import { Socket } from "phoenix";

let socket = new Socket("/socket")
socket.connect()
let channel = socket.channel("oven:proxy", {})

channel.join()
  .receive("ok", resp => { console.log("Joined successfully", resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

channel.on("oven_msg",
m => 
  {console.log(m)}
)


export default socket