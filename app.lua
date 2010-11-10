#!/usr/bin/env wsapi.cgi

require "web"
require "util"

module(..., package.seeall)

--[[ Test App ]]--

local messages = {}

function style ()
    return [[
     <style>
     body  { font: 13px/1.4 'Helvetica Neue', Arial, Helvetica, sans-serif }
     hr { height: 1px; border: 0; color: #ccc; background: #ccc }
     </style>
    ]]
end

function menu ()
   return style() .. [[
    <body>
    <a href="./">Home</a>
    <a href="./chat">Chat</a>
    <a href="./time">Time</a>
    <a href="./about">About</a>
    <hr>
   ]]
end

function escape_tags (s)
    return string.gsub(string.gsub(s, "<", "&lt;"), ">", "&gt;")
end

function chat ()
    -- ask for username
    local username = ok (menu(), [[
            <form method=POST>
            Username <input id=text name=username>
            <input type=hidden name=cid value="<# cid #>">
            <input type=submit value=Join>
            </form>
            <script>document.forms[0].elements[0].focus()</script>
        ]]).params.username
    -- go chatting    
    while true do
        out = menu() .. [[
                <form method=POST>
                <input id=text name=text>
                <input type=hidden name=cid value="<# cid #>">
                <input type=submit value=Post>
                </form>
                <script>document.forms[0].elements[0].focus()</script>
              ]]
        out = out .. table.concat(messages, "<br>")
        local newmsg = ok (out).params.text
        if newmsg and #newmsg > 0 then
            table.insert (messages, username .. "> " .. newmsg)
            seeother ("./chat?cid=<# cid #>")
        end
    end
end
get ("/chat", chat)


function index () 
    local answer
    repeat
        answer = ok (menu(), [[
            <h1>Welcome!</h1> 
            <form method=POST action=click>
            <input name=q>
            <input type=submit>
            <input type=hidden name=cid value="<# cid #>">
            </form>
        ]])
    until #answer.params.q > 0
    ok (menu(), '<a href="result?cid=<# cid #>">click here</a>')
    while true do
        ok (menu(), "You said: ", answer.params.q)
    end
end
get ("/", index)


function thanks ()
    ok "Thanks!"
end
get ("/thanks", thanks)


get ("/about", 
    function ()
        ok (menu(), "Example app for coroutine test")
    end)


function time ()
    local r = ok (menu(), [[
        <form method=POST>
        Age: <input name=age><input type=submit>
        <input type=hidden name=cid value="<# cid #>">
        </form>
    ]])
    ok (menu(), "It was ", util.age(tonumber(r.params.age)))
end
get ("/time", time)
