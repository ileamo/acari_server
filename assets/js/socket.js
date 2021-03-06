// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket,
// and connect at the socket path in "lib/web/endpoint.ex".
//
// Pass the token on params as below. Or remove it
// from the params if you are not using authentication.
import {
  Socket
} from "phoenix"

let socket = new Socket("/socket", {
  params: {
    token: window.userToken,
    conn: window.acari_server_conn
  }
})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "lib/web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "lib/web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/3" function
// in "lib/web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket, _connect_info) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, connect to the socket:
socket.connect()

// Now that you are connected, you can join channels with a topic:



// Lobby Channel
let channel = socket.channel("room:lobby", {})

let messagesBadge = document.querySelector("#num-of-mes")
let messagesContainer = document.querySelector("#event-log")
let statisticsContainer = document.querySelector("#statistics")
let progressContainer = document.querySelector("#progress")
let sessionsContainer = document.querySelector("#sessions")
let alertContainer = document.querySelector("#alert-server-bd")

channel.on("link_event", payload => {
  if (payload.reload) {
    document.location.reload(true);
  } else if (payload.redraw_chart) {
    make_chart()
  } else {
    if (alertContainer && ("alert" in payload)) {
      alertContainer.innerHTML = `${payload.alert}`
    }
    if (statisticsContainer && payload.statistics) {
      statisticsContainer.innerHTML = `${payload.statistics}`
    }
    if (progressContainer && payload.progress) {
      progressContainer.innerHTML = `${payload.progress}`
    }
    if (sessionsContainer && payload.sessions) {
      sessionsContainer.innerHTML = `${payload.sessions}`
      $('[data-toggle="popover"]').popover()
    }
  }
})

// Messages

document.getElementById("collapseMessagesList").addEventListener("mouseenter", mouseOverCollapseMessagesList);
document.getElementById("collapseMessagesList").addEventListener("mouseleave", mouseOutCollapseMessagesList);

let is_messages_freeze = false
let last_messages = messagesContainer.innerHTML
let freese_timeout

function mouseOverCollapseMessagesList(e) {
  if (is_messages_freeze == false) {
    is_messages_freeze = true
    freese_timeout = setTimeout(
      () => {
        is_messages_freeze = null
        messagesContainer.innerHTML = last_messages
      },
      5 * 1000
    )
  }
}

function mouseOutCollapseMessagesList() {
  clearTimeout(freese_timeout)
  is_messages_freeze = false
  messagesContainer.innerHTML = last_messages
}

channel.on("link_event_mes", function(payload) {
  if (global.osmMap && payload.events) {
    global.osmMap(payload.events)
  }

  if (messagesBadge && payload.num_of_mes != null) {
    messagesBadge.innerText = payload.num_of_mes
  }
  if (messagesContainer && payload.messages != null) {
    last_messages = payload.messages
    if (!is_messages_freeze) {
      messagesContainer.innerHTML = payload.messages
    }
  }
})


//Chat

let chat_msg_timeout
channel.on('shout', function(payload) { // listen to the 'shout' event
  let div
  if (payload.message) {
    div = document.createElement("div");
    div.innerHTML = payload.message;
    localStorage.setItem("chat_msg_id", payload.chat_msg_id)
    localStorage.setItem("chat_msg_timestamp", payload.chat_msg_timestamp)
  }
  if ($('#usersChat').is(":visible")) {
    user_list.innerHTML = payload.chat_users
    if (div) {
      msg_list.appendChild(div)
    }
    msg_list.scrollTop = msg_list.scrollHeight - msg_list.clientHeight;
  } else if (div) {
    $('#chatMessage').removeClass('d-none')
    msg_list_popup.appendChild(div)
    msg_list_popup.scrollTop = msg_list_popup.scrollHeight - msg_list_popup.clientHeight;
    clearTimeout(chat_msg_timeout)
    chat_msg_timeout = setTimeout(
      () => {
        $('#chatMessage').addClass('d-none')
      },
      5 * 1000
    );
  }
});

channel.on('about_system', function(payload) {
  $('#about-system-div').html(payload.message)
  $('#AboutSystem').modal('show')
})

channel.join()
  .receive("ok", resp => {
    //console.log("Joined successfully", resp)
    if (resp.alert) {
      $('#navbar-warning')
      .removeClass('d-none')
      .attr({
        title: resp.alert
      });
    }
    if (localStorage.showUsersChat != 'show') {
      channel.push('get_chat_msgs', {
        id: localStorage.getItem("chat_msg_id"),
        timestamp: localStorage.getItem("chat_msg_timestamp")
      })
    }
  })
  .receive("error", resp => {
    console.log("Unable to join", resp)
  })


let msg_list = document.getElementById('chat-msg-list'); // list of messages.
let user_list = document.getElementById('chat-msg-user-list'); // list of messages.
let msg_list_popup = document.getElementById('chat-msg-list-popup')
let msg = document.getElementById('chat-msg'); // message input field

// "listen" for the [Enter] keypress event to send a message:
msg.addEventListener('keyup', function(event) {
  if (event.keyCode == 13) {
    if (msg.value.match(/^\s*$/) === null) {
      channel.push('shout', {
        message: msg.value
      });
    }
    msg.value = '';
  }
});

$('#usersChat').on('hide.bs.collapse', function() {
  localStorage.showUsersChat = 'hide';
})

$('#usersChat').on('show.bs.collapse', function() {
  localStorage.showUsersChat = 'show'
  channel.push('init_chat', {});
  msg_list.innerHTML = ""
  $('#chatMessage').addClass('d-none')
  msg_list_popup.innerHTML = ""
})

$('#usersChat').collapse(localStorage.showUsersChat || 'hide')

// AboutSystem

let about_system_menus = document.getElementsByClassName("about-system-menu")
for (var i = 0; i < about_system_menus.length; i++) {
  about_system_menus[i].addEventListener("click", function(event) {
    channel.push('get_about_system', {});
  })
}


export default socket
