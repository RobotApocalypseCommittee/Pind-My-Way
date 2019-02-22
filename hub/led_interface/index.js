const EventEmitter = require('events');
const WebSocket = require("ws");
const Buffer = require("buffer")


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

  _registerNewGlove(ws, data) {
    console.log("[WS] New registration: ", data);
    // Data is binary buffer
    if (data[0] === 0 ){
      // Left Glove
      this.gloves.left = ws
      console.log("[WS] New left glove");
      ws.on("close", ()=> {
        this.gloves.left = null
        this.emit("stateChange")
      })
    } else {
      this.gloves.right = ws
      console.log("[WS] New right glove");
      ws.on("close", ()=> {
        this.gloves.right = null
        this.emit("stateChange")
      })
    }
    this.emit("stateChange")
  }

  broadcast(data) {
      this.server.clients.forEach((client)=>{
        client.send(data, {binary: true})
      })
  }

  signalDirection(direction, level) {
    let toSend = Buffer.alloc(3)
    // Command 1 = direction
    toSend.writeUInt8(0x1, 0)
    // -3 to 4
    toSend.writeInt8(direction, 1)
    // 0, 1 or 2
    toSend.writeUInt8(level, 2)
    this.broadcast(toSend)
  }
  signalData(track, number, r, g, b) {
    let toSend = Buffer.alloc(6)
    // Command 2 = led override
    toSend.writeUInt8(0x2, 0)
    // 0 or 1, there are two displays
    toSend.writeUInt8(track, 1)
    // from 0 to 6
    toSend.writeUInt8(number, 2)
    // Out of 255
    toSend.writeUInt8(r, 3)
    toSend.writeUInt8(g, 4)
    toSend.writeUInt8(b, 5)
    this.broadcast(toSend)
  }
  signalNeutral() {
    let toSend = Buffer.alloc(1)
    toSend.writeUInt8(0x3, 0)
    this.broadcast(toSend)
  }
  signalRelax() {
    let toSend = Buffer.alloc(1)
    toSend.writeUInt8(0x4, 0)
    this.broadcast(toSend)
  }
}

module.exports = GlovesLink
