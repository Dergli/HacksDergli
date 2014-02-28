require "socket"
require "openssl"
require "net/https"
require "uri"
class MITMTool
  puts "V is for Vengeance; The Vengeance Switch"
  puts "Remote host to proxy: "
  host = gets
  puts "Fowarding port to proxy through: "
  hport = gets
  puts "Remote Host SSL Port: "
  port = gets
  remote_host = host.chomp
  remote_port = port.chomp
  listen_port = hport.chomp
  max_threads = 10
  threads = []
  logfilecs = "logs/sslproxy.log" #logfiles will be prefixed with timestamp
  logfilesc = "logs/sslproxy.log" #logfiles will be prefixed with timestamp
  cert = "ca/vswitch.crt"
  key = "ca/vswitch.key"
  puts "Starting vSwitch"
  server = TCPServer.new(nil, listen_port)
  lssl_context = OpenSSL::SSL::SSLContext.new(:SSLv3_server)
                 OpenSSL::SSL::SSLContext.new(:SSLv2_server)
                 OpenSSL::SSL::SSLContext.new(:TLSv1_server)
  lssl_context.cert = OpenSSL::X509::Certificate.new(File.open(cert))
  lssl_context.key = OpenSSL::PKey::RSA.new(File.open(key))
  lssl_socket = OpenSSL::SSL::SSLServer.new(server,lssl_context)
  while true
    # Start a new thread for every client connection.
    puts "waiting for connections"
    threads << Thread.new(lssl_socket.accept) do |client_socket|
      begin
        trap("INT") {OpenSSL::SSL::SSLError}
        time = Time.now.to_i
        puts "#{Thread.current}: got a client connection"
        puts "Successful MitM: #{time}"
        logcs = '' << logfilecs
        logsc = '' << logfilesc
        cs = File.new(logcs,"a")
        sc = File.new(logsc,"a")
      begin
        trap("INT") {OpenSSL::SSL::SSLError}
          server_socket = TCPSocket.new(remote_host, remote_port)
          ssl_context = OpenSSL::SSL::SSLContext.new(:TLSv1_client)
                        OpenSSL::SSL::SSLContext.new(:SSLv3_client)
                        OpenSSL::SSL::SSLContext.new(:SSLv2_client)
          ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
          ssl_socket = OpenSSL::SSL::SSLSocket.new(server_socket, ssl_context)
          ssl_socket.sync_close = true
          ssl_socket.connect
      rescue Errno::ECONNREFUSED
      rescue OpenSSL::SSL::SSLError
          client_socket.close
          client_socket.close rescue OpenSSL::X509::CertificateError
          client_socket.close rescue OpenSSL::SSL::SSLError
          client_socket.close rescue OpenSSL::OpenSSLError
          raise
        end
        puts "#{Thread.current}: connected to server at #{remote_host}:#{remote_port}"
        while true
          # Wait for data to be available on either socket.
          (ready_sockets, dummy, dummy) = IO.select([client_socket, ssl_socket])
          begin
             trap('INT') {OpenSSL::SSL::VERIFY_NONE}
            ready_sockets.each do |socket|
              uri = URI.parse('https://'+remote_host)
              http = Net::HTTP.new(uri.host, uri.port)
              data = socket.readpartial(4096)
              if socket == client_socket
                # Read from client, write to server.
                ssl_socket.write data
                ssl_socket.flush
                request = Net::HTTP::Get.new(uri.request_uri)
                cs.write data
              elsif socket == ssl_socket
                # Read from server, write to client.
                client_socket.write data
                client_socket.flush
                sc.write data
              end
            end
          rescue OpenSSL::SSL::SSLError
          rescue OpenSSL::OpenSSLError
          rescue OpenSSL::SSL::SSLError
          rescue OpenSSL::X509::CertificateError
          rescue OpenSSL::SSL::Session::SessionError
          rescue OpenSSL::X509::NameError
          rescue OpenSSL::X509::RequestError
          rescue OpenSSL::X509::RevokedError
          rescue OpenSSL::X509::AttributeError
          rescue EOFError
            break
          end
        end
      rescue StandardError => e
        puts "Thread #{Thread.current} got exception #{e.inspect}"
      end
      puts "#{Thread.current}: closing the connections"
      client_socket.close rescue OpenSSL::X509::CertificateError
      client_socket.close rescue OpenSSL::SSL::SSLError
      client_socket.close rescue OpenSSL::OpenSSLError
      ssl_socket.close rescue OpenSSL::SSL::Session::SessionError
      ssl_socket.close rescue OpenSSL::SSL::SSLError
      ssl_socket.close rescue OpenSSL::OpenSSLError
      client_socket.close rescue StandardError
      ssl_socket.close rescue StandardError
    end
    puts "#{threads.size} threads running"
    threads = threads.select { |t| t.alive? ? true : (t.join; false) }
    while threads.size >= max_threads
      sleep 1
      threads = threads.select { |t| t.alive? ? true : (t.join; false) }
    end
  end
end