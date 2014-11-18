#This file is part of Shortest-Path-Server.
#Copyright (c) 2014 Christian Sanders
#Shortest-Path-Server is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#Shortest-Path-Server is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#You should have received a copy of the GNU General Public License along with Shortest-Path-Server. If not, see http://www.gnu.org/licenses/.

require 'priority_queue'

class SPS

  def initialize(filepath=nil)
    #raise ArgumentError, "No file given" if filepath == nil
    output = ""
    count = 0
    request = true
    @request_array = []
    @remaining_array = []
    @vertices = {}

    File.open("/home/wolph/projects/shortest-path-server/data/map1.bin", 'rb') do |file|
      until file.eof?
        if request
          s = file.read(2)
          value = s.unpack('v')
          value = value[0]
          @request_array.push(value)
          count += 1
          request = false if count == 3
        else
          s = file.read(2)
          value = s.unpack('v')
          value = value[0]
          @remaining_array.push(value)
        end
      end
    end

    get_vertices
    shortest_path = dijkstra(@request_array[0], @request_array[1])
    if shortest_path == nil
      puts "No path from #{@request_array[0]} to #{@request_array[1]}"
    else
      shortest_path.unshift(@request_array[1])
      shortest_path.push(@request_array[0])
      while shortest_path.size != 0
        if output == ""
          output = output + "#{shortest_path.pop}"
        else
          output = output + "->#{shortest_path.pop}"
        end
      end
      puts "#{output} (#{@weight})"
    end
  end

  def get_vertices
    count = 1
    x = 0
    number_of_vertices = @request_array[2]
    while count <= number_of_vertices
      edges = Hash.new
      vertex_name = @remaining_array[x]
      edge = @remaining_array[x+1]
      weight = @remaining_array[x+2]
      edges[edge] = weight
      while @remaining_array[x+3] == vertex_name
        x += 3
        edge = @remaining_array[x+1]
        weight = @remaining_array[x+2]
        edges[edge] = weight
        count += 1
      end
      add_vertex(vertex_name, edges)
      x += 3
      count += 1
    end
  end

  def add_vertex(name, edges)
    @vertices[name] = edges
  end

  def dijkstra(start_node, end_node)
    infinity = Float::INFINITY
    @weight = infinity
    @path = []
    x = 1
    distance = {}
    previous = {}
    to_search = PriorityQueue.new

    @vertices.each do |vertex, value|
      if vertex == start_node
        distance[vertex] = 0
        to_search[0] << vertex
      else
        distance[vertex] = infinity
        to_search[x] << vertex
        x += 1
      end
      previous[vertex] = nil
    end

    while to_search.size != 0
      to_test = to_search.shift

      break if to_test == nil
      break if distance[to_test] == infinity

      @vertices[to_test].each do |neighbor, value|
        alt = distance[to_test] + @vertices[to_test][neighbor]
        distance[neighbor] = 0 if distance[neighbor] == nil
        if alt < distance[neighbor]
          distance[neighbor] = alt
          previous[neighbor] = to_test
          to_search[alt] << neighbor
        end

        if neighbor == end_node and alt < @weight
          @path = []
          while previous[to_test]
            @path.push(to_test)
            to_test = previous[to_test]
          end
          @weight = alt
        end
      end
    end
    return nil if @path.size == 0
    return @path
  end
end
