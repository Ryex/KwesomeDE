-------------------------------------------
-- @author https://github.com/Kasper24
-- @copyright 2021-2022 Kasper24
-------------------------------------------

local beautiful = require("beautiful")
local naughty = require("naughty")

local timed_load = require('helpers.timed_load')

local gitlab_daemon = timed_load.require("daemons.web.gitlab")

local icons =
{
    "gitlab",
    "com.github.zren.gitlabissues",
    "gitlab-tray",
    "folder-gitlab",
    "io.gitlab.osslugaru.Lugaru",
    "com.gitlab.davem.ClamTk",
    "mailer",
    "preferences-mail.svg",
    "kmail"
}

gitlab_daemon:connect_signal("new_pr", function(self, pr)
    naughty.notification
    {
        app_font_icon = beautiful.gitlab_icon,
        app_icon = icons,
        app_name = "Gitlab",
        font_icon = beautiful.envelope_icon,
        icon = icons,
        title = "New PR",
        text = pr.title,
        category = "email.arrived"
    }
end)