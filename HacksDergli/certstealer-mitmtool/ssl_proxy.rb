require "socket"
require "openssl"
class SSLProxy
  puts "Remote host to proxy: "
  host = gets
  puts " Fowarding port to proxy through: "
  hport = gets
  puts "Remote Host SSL Port: "
  port = gets
  remote_host = host.chomp
  remote_port = port.chomp
  listen_port = hport.chomp
  max_threads = 5
  threads = []
  logfilecs = "sslproxy.log" #logfiles will be prefixed with timestamp
  logfilesc = "sslproxy.log" #logfiles will be prefixed with timestamp
  cert = "ca/vswitch.crt"
  key = "ca/vswitch.key"


  puts "starting server"
  server = TCPServer.new(nil, listen_port)
  lssl_context = OpenSSL::SSL::SSLContext.new(:SSLv3_server)
  lssl_context.cert = OpenSSL::X509::Certificate.new(File.open(cert))
  lssl_context.key = OpenSSL::PKey::RSA.new(File.open(key))
  lssl_socket = OpenSSL::SSL::SSLServer.new(server,lssl_context)
  while true
    # Start a new thread for every client connection.
    puts "waiting for connections"
    threads << Thread.new(lssl_socket.accept) do |client_socket|
      begin
        time = Time.now.to_i
        puts "#{Thread.current}: got a client connection"
        puts "writing to logfiles: #{time}"
        logcs = time.to_s << logfilecs
        logsc = time.to_s << logfilesc
        cs = File.new(logcs,"a")
        sc = File.new(logsc,"a")

        begin
          server_socket = TCPSocket.new(remote_host, remote_port)
          ssl_context = OpenSSL::SSL::SSLContext.new(:TLSv1_client)
          ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
          ssl_socket = OpenSSL::SSL::SSLSocket.new(server_socket, ssl_context)
          ssl_socket.sync_close = true
          ssl_socket.connect
        rescue Errno::ECONNREFUSED
          client_socket.close
          raise
        end
        puts "#{Thread.current}: connected to server at #{remote_host}:#{remote_port}"
        while true
          # Wait for data to be available on either socket.
          (ready_sockets, dummy, dummy) = IO.select([client_socket, ssl_socket])
          begin
            ready_sockets.each do |socket|
              data = socket.readpartial(4096)
              if socket == client_socket
                # Read from client, write to server.
                cs.write data
                ssl_socket.write data
                ssl_socket.flush
              elsif socket == ssl_socket
                # Read from server, write to client.
                sc.write data
                client_socket.write data
                client_socket.flush
              end
            end
          rescue EOFError
            break
          end
        end
      rescue StandardError => e
        puts "Thread #{Thread.current} got exception #{e.inspect}"
      end
      puts "#{Thread.current}: closing the connections"
      client_socket.close rescue StandardError
      ssl_socket.close rescue StandardError
    end

    # Clean up the dead threads, and wait until we have available threads.
    puts "#{threads.size} threads running"
    threads = threads.select { |t| t.alive? ? true : (t.join; false) }
    while threads.size >= max_threads
      sleep 1
      threads = threads.select { |t| t.alive? ? true : (t.join; false) }
    end
  end
end
