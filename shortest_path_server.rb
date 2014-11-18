#This file is part of Shortest-Path-Server.
#Copyright (c) 2014 Christian Sanders
#Shortest-Path-Server is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#Shortest-Path-Server is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#You should have received a copy of the GNU General Public License along with Shortest-Path-Server. If not, see http://www.gnu.org/licenses/.

require 'socket'
solver = Dir.pwd + '/shortest_path_solver'
require solver
include SPS

Socket.tcp_server_loop(7777) do |sock, client_addrinfo|
  begin
    #Copy the raw input into a file
    IO.copy_stream(sock, "/tmp/sps_input")
    #Solve the shortest path and output to a file
    output = path_solver("/tmp/sps_input")
    File.open("/tmp/sps_output", 'w') { |file| file.write(output) }
    #Copy the file to the client
    IO.copy_stream("/tmp/sps_output", sock)
  ensure
    sock.close
  end
end
