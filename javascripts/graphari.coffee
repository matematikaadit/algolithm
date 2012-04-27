$ ->

  width  = 588
  height = 398
  parent = "#main"

  # Drawing Area
  svg = d3.select(parent).append("svg")
          .attr("height", height)
          .attr("width", width)

  # The Lowest Element in Drawing Area
  svg.append("circle")
     .attr("r", 0)
     .attr("id", "lowest")

  lowest = "#lowest"

  nodes = []
  axes  = []
  # Create a node. Create a edge also if intended
  create_node = ->
    n = tick()
    nodes.push(n)

    coord = d3.mouse(this)
    x = coord[0]
    y = coord[1]

    axes[n] = [x, y]

    node_draw()

    create_edge(n, ew.pop()) if ew.length isnt 0

  # bind to the drawing area
  svg.on("click", create_node, false)

  nw = []
  ew = []
  t  = 0
  # tick between t or nw
  tick = ->
    if nw.length isnt 0
      return nw.pop()
    return t++

  # duration and circle radius
  dur = 250
  r   = 15

  color_selected = "red"
  color_normal   = "#4276B6"

  # choose color based on waiting list in ew
  which_color = (d) ->
    if ew.length isnt 0
      return color_selected
    return color_normal

  n  = (d) -> d
  nx = (d) -> axes[d][0]
  ny = (d) -> axes[d][1]
  # draw the node
  node_draw = ->
    # each node consist of circle and text
    ci = svg.selectAll("circle.node")
           .data(nodes, n)

    ci.enter().append("circle")
             .attr("class", "node") .attr("id", (d) -> "circle-#{d}")
             .style("fill", which_color)
             .attr("cx", nx)
             .attr("cy", ny)
             .attr("r", 0)
             .on("click", click_node)
             .on("contextmenu", remove_node)
           .transition()
             .duration(dur)
             .attr("r", r)

    ci.exit().transition()
            .duration(dur)
            .attr("r", 0)
            .remove()

    tx = svg.selectAll("text.node")
           .data(nodes, n)

    tx.enter().append("text")
              .attr("class", "node")
              .attr("x", nx)
              .attr("y", (d) -> ny(d) + 3)
              .text(String)
              .on("click", click_node)
              .on("contextmenu", remove_node)

    tx.exit().remove()

  # action for clicking node
  click_node = (d) ->
    d3.event.stopPropagation()

    # Case I. No node selected before
    if ew.length is 0
      ew.push(d)
      animate_circle_col(d, color_selected)
    # Case II. This node is selected before
    else if ew[0] is d
      ew.pop()
      animate_circle_col(d, color_normal)
    # Case III. The edge exist
    else if edge_exist(ew[0], d)
      animate_circle_col(ew.pop(), color_normal)
    else
      animate_circle_col(d, color_selected)
      create_edge(d, ew.pop())

  # action for removeing node
  remove_node = (d) ->
    d3.event.preventDefault()

    index = nodes.indexOf(d)
    adel = nodes.splice(index, 1)

    nw.push(adel[0])
    nw.sort(d3.descending)
    ew.pop() if ew[0] is adel[0]

    node_draw()

    remove_incident_edge(d)


  # check wether the edge exist or not
  edge_exist = (d1, d2) ->
    for edge in edges
      if (edge.indexOf(d1) isnt -1) and (edge.indexOf(d2) isnt -1)
        return true
    return false

  # animate circle color
  animate_circle_col = (d, color, delay = 0) ->
    d3.select("#circle-#{d}").transition()
      .delay(delay)
      .duration(dur)
      .style("fill", color)

  # variabel that hold edges created in drawing area
  edges = []
  et    = 0
  ekey  = new Object

  # remove incident edge
  remove_incident_edge = (d) ->
    filtered = edges.filter (edge) ->
      if edge.indexOf(d) isnt -1
        return false
      return true

    edges = filtered

    edge_draw()

  # create an edge
  create_edge = (d1, d2) ->
    edges.push([d1, d2])

    #if neighbours[d1]
    #  neighbours[d1].push(d2)
    #else
    #  neighbours[d1] = [d2]

    #if neighbours[d2]
    #  neighbours[d2].push(d1)
    #else
    #  neighbours[d2] = [d1]

    key = et++
    # console.log(key)
    ekey["k#{d1}_#{d2}"] = key
    ekey["k#{d2}_#{d1}"] = key

    edge_draw()

    animate_circle_col(d1, color_normal, dur)
    animate_circle_col(d2, color_normal, dur)

  # edge class
  eclass = (d) ->
    "edge edge-#{d[0]}-#{d[1]} edge-#{d[1]}-#{d[0]}"

  # draw edge
  edge_draw = ->
    li = svg.selectAll("line.edge")
           .data(edges, (d) -> ekey["k#{d[0]}_#{d[1]}"])

    li.enter().insert("line", lowest)
              .attr("class", eclass)
              .attr("x1", exm)
              .attr("y1", eym)
              .attr("x2", exm)
              .attr("y2", eym)
              .style("stroke", color_selected)
              .on("click", (d) -> d3.event.stopPropagation())
              .on("contextmenu", remove_edge)
            .transition()
              .attr("x1", ex1)
              .attr("y1", ey1)
              .attr("x2", ex2)
              .attr("y2", ey2)
            .transition()
              .delay(dur)
              .style("stroke", color_normal)

    li.exit().transition()
             .duration(dur)
             .attr("x1", exm)
             .attr("y1", eym)
             .attr("x2", exm)
             .attr("y2", eym)
             .remove()

  # remove an edge
  remove_edge = (d) ->
    d3.event.preventDefault()

    index = edges.indexOf(d)
    #console.log(index)
    index = edges.indexOf(d.reverse()) if index is -1
    #console.log(index)

    edges.splice(index, 1) if index isnt -1

    edge_draw()

  # various position helper
  ex1 = (d) -> nx(d[0])
  ex2 = (d) -> nx(d[1])
  ey1 = (d) -> ny(d[0])
  ey2 = (d) -> ny(d[1])
  exm = (d) -> (ex1(d) + ex2(d))/2
  eym = (d) -> (ey1(d) + ey2(d))/2

  # animating edge
  animate_edge_col = (d, color, delay = 0) ->
    d3.selectAll("line.edge-#{d[0]}-#{d[1]}").transition()
      .delay(delay)
      .duration(dur)
      .style("stroke", color)

  #--------------------ALGO Time--------------------#
  #
  # let's save the princess
  #
  # bfs algorithm
  bfs = (nodes, source) ->
    for node in nodes
      color    node, color_unvisited
      parent   node, null
      distance node, Infinity

    color    source, color_visited
    distance source, 0

    Q = []

    Q.push source

    while Q.length isnt 0
      p = Q.shift()
      color p, color_finished

      for node in neighbour p
        if color(node) is color_unvisited
          color    node, color_visited
          parent   node, p
          distance node, distance(p) + 1
          Q.push   node

  # dfs stuff
  time = 0
  d = []
  f = []

  # dfs algorithm
  dfs = (nodes) ->
    for node in nodes
      color node, color_unvisited
      parent node, null

    time = 0
    for node in nodes
      if color(node) is color_unvisited
        dfs_visit(node)

  dfs_visit = (node) ->
    color node, color_visited
    time++
    d[node] = time

    for v in neighbour(node)
      if color(v) is color_unvisited
        parent v, node
        dfs_visit(v)

    color node, color_finished
    time++
    f[node] = time

  # various color
  color_unvisited = "gray"
  color_visited   =  "brown"
  color_finished  = "black"


  colors    = []

  # coloring node
  color = (node, color = null) ->
    if color is null
      return colors[node]
    switch color
      when color_unvisited
        animate_circle_col(node, color)
        colors[node] = color
      when color_visited, color_finished
        animate_circle_col(node, color, tack())
        colors[node] = color
      else
        animate_circle_col(node, color)

    return color

  at = 0

  # same as tick but multiple of duration
  tack = ->
    at++
    at * dur

  parents   = []
  distances = []

  # set or get the parent of a node
  parent = (node, par = null) ->
    if par is null
      return parents[node]
    parents[node] = par
    return par

  # set or get the distance of a node
  distance = (node, dis = null) ->
    if dis is null
      return distances[node]
    distances[node] = dis
    return dis

  # get the neighbours of a node
  neighbour = (node) ->
    nbh = []
    for edge in edges
      if edge[0] is node
        nbh.push(edge[1])
      else if edge[1] is node
        nbh.push(edge[0])
    return nbh

  # clear the color of nodes in area
  clear_col = ->
    for node in nodes
      color node, color_normal

  # reset the area
  reset_area = ->
    nodes = []
    edges = []
    node_draw()
    edge_draw()

  $("#bfs").click (e) ->
    e.preventDefault()
    at = 0
    tmp = dur
    dur = 1000
    bfs(nodes, nodes[0])
    dur = tmp

  $("#dfs").click (e) ->
    e.preventDefault()
    at = 0
    tmp = dur
    dur = 1000
    dfs(nodes)
    dur = tmp

  $("#clear").click (e) ->
    e.preventDefault()
    clear_col()

  $("#reset").click (e) ->
    e.preventDefault()
    reset_area()
