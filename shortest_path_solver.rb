#This file is part of Shortest-Path-Server.
#Copyright (c) 2014 Christian Sanders
#Shortest-Path-Server is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
#Shortest-Path-Server is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#You should have received a copy of the GNU General Public License along with Shortest-Path-Server. If not, see http://www.gnu.org/licenses/.

require 'priority_queue'

#This was originally a class but is easier to work with as a module
module SPS

  #path_solver is the meat of this project, accepting the input, running the algorithm, and giving the output
  def path_solver(filepath=nil)
    raise ArgumentError, "No file given" if filepath == nil
    output = ""
    count = 0
    request = true
    @request_array = []
    @remaining_array = []
    @vertices = {}

    File.open(filepath, 'rb') do |file|
      until file.eof?
        #First we get our initial edge, our destination edge, and the number of edges
        if request
          #by reading in 2 bytes at a time we are able to use string.unpack to get an easier to use value
          s = file.read(2)
          value = s.unpack('v')
          #however, string.unpack returns an array, which we don't want.  This gets us just the value
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
      out = "No path from #{@request_array[0]} to #{@request_array[1]}"
      puts out
      return out
    else
      #Here we massage the output to the format that we want
      shortest_path.unshift(@request_array[1])
      shortest_path.push(@request_array[0])
      while shortest_path.size != 0
        if output == ""
          output = output + "#{shortest_path.pop}"
        else
          output = output + "->#{shortest_path.pop}"
        end
      end
      out = "#{output} (#{@weight})"
      puts out
      return out
    end
  end

  #get_vertices populates the vertices array, giving us each edge, it's neighbors, and the cost of traveling to each neighbor
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
      #this checks to see if the next vertex is actually the same vertex that we are already on, but with a different
      #neighbor.  If it is, we'll continue to populate the current vertex rather than generate a new one
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

  #an implementation of the dijkstra algorithm to get shortest and most cost-effective path
  def dijkstra(start_node, end_node)
    infinity = Float::INFINITY
    @weight = infinity
    @path = []
    x = 1
    distance = {}
    previous = {}
    to_search = PriorityQueue.new

    #run over the initial vertices to populate our initial arrays
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

    #as long as we have edges to check, we'll check each edge
    while to_search.size != 0
      to_test = to_search.shift

      #if we somehow get a nil value or if we come across an edge with an infinite distance to
      #the source, we stop searching as we have run out of edges to check
      break if to_test == nil
      break if distance[to_test] == infinity

      #here we calculate all of the possibilities as well as their costs at each node
      @vertices[to_test].each do |neighbor, value|
        alt = distance[to_test] + @vertices[to_test][neighbor]
        distance[neighbor] = 0 if distance[neighbor] == nil
        if alt < distance[neighbor]
          distance[neighbor] = alt
          previous[neighbor] = to_test
          to_search[alt] << neighbor
        end

        #here we check if we have a path to the exit edge.  If we do, we check to make sure that
        #we don't already have a faster/more cost-effective way of getting there.  If we don't,
        #the newly discovered route becomes the best path
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
    #If we are unable to locate a path to the exit node we return nil
    return nil if @path.size == 0
    return @path
  end
end
