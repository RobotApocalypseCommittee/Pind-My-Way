const EventEmitter = require('events');
const WebSocket = require("ws");
const Buffer = require("buffer")


// There are 3 levels - 0, 1, 2; the numbers assigned are ms blink periods
const blinkDelays = [500, 250, 100]


const directionIDs = ["forward", "left", "right", "reverse"]

class GlovesLink extends EventEmitter {
  constructor() {
    super()
    this.gloves = {left:null, right:null}
    this.server = new WebSocket.Server({port: 8080})
    this.server.on("connection", (ws)=>{
      console.log("[WS] New connection")
      ws.on("close", ()=>console.log("[WS] Closed Connection"))
      ws.once("message", this._registerNewGlove.bind(this, ws))
    })
  }
  get ready() {
    return (this.gloves.left !== null && this.gloves.right !== null)
  }

  _registerNewGlove(ws, data) {
    // Data is binary buffer
    if (data[0] === 0 ){
      // Left Glove
      this.gloves.left = ws
      ws.on("close", ()=> {
        this.gloves.left = null
        this.emit("unready")
      })
    } else {
      this.gloves.right = ws
      ws.on("close", ()=> {
        this.gloves.right = null
        this.emit("unready")
      })
    }
    if (this.ready) {
      this.emit("ready")
    }
  }

  broadcast(data) {
    if (this.ready) {
      this.server.clients.forEach((client)=>{
        client.send(data, {binary: true})
      })
    } else {
      throw new Error("Cannot broadcast: GlovesLink is not ready.")
    }
  }

  signalDirection(direction, level) {
    let dirID = directionIDs.indexOf(direction)
    if (dirID < 0) {
      throw new Error("Invalid Direction Specified")
    }
    let toSend = Buffer.alloc(4)
    toSend.writeUInt8(0x1, 0)
    toSend.writeUInt8(direction, 1)
    toSend.writeInt16LE(level, 2)
    this.broadcast(toSend)
  }

  signalInfo() {
    // TODO: Until william figures out what the glove will be able to display, I cannot make a data format for it...
  }
}

module.exports = GlovesLink
