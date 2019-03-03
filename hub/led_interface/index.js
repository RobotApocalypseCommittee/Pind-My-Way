const EventEmitter = require('events');
const WebSocket = require("ws");
const winston = require("winston")


class GlovesLink extends EventEmitter {
  constructor() {
    super()
    this.gloves = {left:null, right:null}
    this.server = new WebSocket.Server({port: 8080})
    this.server.on("connection", (ws)=>{
      winston.info("[WS] New connection")
      ws.on("close", ()=>winston.info("[WS] Closed Connection"))
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
    // Command 1 = direction
    let toSend = Buffer.from([0x1, direction, level])

    this.broadcast(toSend)
  }
  signalData(track, number, r, g, b) {
    // Command 2 = led override
    // 0 or 1, there are two displays
    // from 0 to 6
    // Out of 255
    let toSend = Buffer.from([0x2, track, number, r, g, b])
    this.broadcast(toSend)
  }
  signalNeutral() {
    let toSend = Buffer.from([0x3])
    this.broadcast(toSend)
  }
  signalRelax() {
    let toSend = Buffer.from([0x4])
    this.broadcast(toSend)
  }
}

module.exports = GlovesLink
