_parent = (pos) ->
  return Math.floor((pos -1) / 2)

_children = (pos) ->
  return [2 * pos + 1, 2 * pos + 2]

pq_insert = (list, key, value) ->
  pos = list.push [key, value]
  parentPos = parent pos
  while value > list[parentPos][1]
    list[pos] = list[parentPos]
    list[parentPos] = value
    pos = parentPos
    parentPos = parent pos
