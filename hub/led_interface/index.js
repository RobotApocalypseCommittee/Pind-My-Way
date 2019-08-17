const EventEmitter = require('events');
const WebSocket = require("ws");
const winston = require("winston")
const readline = require("readline")


class GlovesLink extends EventEmitter {
  constructor() {
    super()
    this.gloves = {left:null, right:null}
    this.server = new WebSocket.Server({port: 8080})
    this.server.on("connection", (ws)=>{
      winston.info("[WS] New connection")
      this.resetCurrentData()
      ws.on("close", ()=>winston.info("[WS] Closed Connection"))
      ws.once("message", this._registerNewGlove.bind(this, ws))
    })
    this.resetCurrentData()
  }

  resetCurrentData() {
    this.currentData = [
      {data: null, r: null, g: null, b: null},
      {data: null, r: null, g: null, b: null}
    ]
  }

  _registerNewGlove(ws, data) {
    console.log("[WS] New registration: ", data);
    // Data is binary buffer
    if (data[0] === 0 ){
      // Left Glove
      this.gloves.left = ws
      winston.info("[WS] New left glove");
      ws.on("close", ()=> {
        this.gloves.left = null
        this.emit("stateChange")
      })
    } else {
      this.gloves.right = ws
      winston.info("[WS] New right glove");
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
    //Input dir = -3 to 4, but to avoid signed thingies we scale to 0-7
    direction = direction + 3
    let toSend = Buffer.from([0x1, direction, level])

    this.broadcast(toSend)
  }
  signalData(track, number, r, g, b) {
    // Figure out whether an update is needed
    if (this.currentData[track].data !== number) {
      this.currentData[track] = {data: number, r: r, g:g, b:b}
      let toSendArray = [0x2]
      for (let i = 0; i < this.currentData.length; i++) {
        toSendArray.push(this.currentData[i].data)
        toSendArray.push(this.currentData[i].r)
        toSendArray.push(this.currentData[i].g)
        toSendArray.push(this.currentData[i].b)
      }
      let toSend = Buffer.from(toSendArray)
      this.broadcast(toSend)
    }
  }
  signalNeutral() {
    let toSend = Buffer.from([0x3])
    this.broadcast(toSend)
  }
  signalRelax() {
    let toSend = Buffer.from([0x4])
    this.broadcast(toSend)
  }
  test(cycle) {
    var currentTest = 0
    let f = ()=>{
      if (currentTest === 0) {
        this.signalRelax()
        console.log("Relax")
      } else if (currentTest === 1) {
        console.log("Neutral")
        this.signalNeutral()
      } else if (currentTest > 1 && currentTest < 10) {
        console.log("Arrow", currentTest - 5, 0)
        this.signalDirection(currentTest - 5, 0)
      } else if (currentTest > 9 && currentTest < 13) {
        console.log("Arrow", 0, (currentTest-1) % 3 )
        this.signalDirection(0, (currentTest-1) % 3 )
      } else if (currentTest > 12 && currentTest < 18) {
        console.log("Data", currentTest % 2, currentTest - 12)
        this.signalData(currentTest % 2, currentTest - 10, 255, (currentTest %2) ? 255: 0, 0)
      }
      currentTest = currentTest + 1;
      if (currentTest > 17) {
        currentTest = 0;
      }
    }
    var rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      terminal: false
    });
    if (cycle > 0) {
      setInterval(f, 1000*cycle)
    } else {
      rl.on('line', f)
    }
  }
}

module.exports = GlovesLink
