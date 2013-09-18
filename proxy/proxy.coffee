_            = require "underscore"
fs           = require "fs"
sys          = require "sys"
path         = require "path"
exec         = require("child_process").exec
httpProxy    = require "http-proxy"
config       = require "../websites.json"
proxyServer  = null
defPort      = 3000
defFirstPort = 3000
defIncrement = 10

config.ports = {}
config.settings ||= {}
config.settings.user ||= "root"
config.redirects = {}
config.ports.current = config.ports.first || defFirstPort
config.ports.increment ||= defIncrement
config.rootPath = "/data/websites" # path.join path.dirname(require.main.filename), ".."
config.logPath = path.join config.rootPath, "..", "logs"

for website in config.websites
  website.hosts ||= []
  website.hosts.push website.host if website.host

  website.redirects ||= []
  website.redirects.push website.redirect if website.redirect

  website.dir ||= website.hosts[0]
  website.port = config.ports.current

  config.ports[host] = config.ports.current for host in website.hosts
  config.redirects[redirect] = website.hosts[0] for redirect in website.redirects
  config.ports.current += config.ports.increment

runProxy = () ->
  if not proxyServer?
    proxyServer = httpProxy.createServer (req, res, proxy) ->#
      host = req.headers.host
      if config.redirects[host]?
        location = "http://#{config.redirects[host]}/"
        res.writeHead 301,
          Location: location
        res.end()
      else
        target =
          host: "localhost"
          port: config.ports[host]
        target.port = config.ports.first || defPort if not target.port?
        target.buffer = httpProxy.buffer req
        proxy.proxyRequest req, res, target
    .listen 80
 
    proxyServer.proxy.on "proxyError", (err, req, res) ->
      res.writeHead 500,
        "Content-Type": "text/html"
      res.write """
        <html>
          <body>
            <h1>
              Not available
            </h1>
            Sorry, it looks like you've reached a site that is currently unavailable.<br/>
            Try again later
          </body>
        </html>
      """
      res.end()

    for website in config.websites
      webPath = path.join config.rootPath, website.dir
      mongoLockPath = "#{webPath}/.meteor/local/db/mongod.lock"
      fs.unlinkSync mongoLockPath if fs.existsSync mongoLockPath
      pathExport = ""
      pathExport = " PATH=$PATH:/#{config.settings.user}/.nvm/#{config.settings.nvm}/bin/" if config.settings.nvm?
      cmd = """
        export HOME=/#{config.settings.user}/ #{pathExport} &&
        cd #{webPath} &&
        exec mrt -p #{website.port} --production >> #{config.logPath}/#{website.dir}.log
      """
      meteorInstance = exec cmd, (err, stdout, stderr) ->
        console.log "stdout: #{stdout}" if stdout?
        console.log "stderr: #{stderr}" if stderr?
        console.log "err: #{err}" if err?

runProxy()
