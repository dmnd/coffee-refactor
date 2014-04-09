coffee = require 'coffee-script'
_ = require 'underscore'
{ inspect } = require 'util'
{ Range } = require 'atom'


pad = (str, len, pad = ' ') ->
  while str.length < len
    str += pad
  str

padL = (str, len, pad = ' ') ->
  while str.length < len
    str = pad + str
  str

locationDataToRange = ({ first_line, first_column, last_line, last_column }) ->
  new Range [first_line, first_column], [last_line, last_column + 1]


module.exports = class Refactor

  constructor: (code) ->
    @node = Node.create coffee.nodes code

  find: (range) ->
    return [] unless range?
    @node.find range

class Node

  @create: (data, parentNode, depth, type) ->
    unless depth?
      new RootNode data
    else if data.body?
      new TopNode data, parentNode, depth, type
    else
      new Node data, parentNode, depth, type

  constructor: ({
    locationData
    parent
    body
    expressions
    params
    args
    properties
    objects
    variable
    value
    first
    second
    base
    name
  }, @parentNode, @depth = 0, @type = 'body') ->

    @range = locationDataToRange locationData
    @children = []
    @params = []

    if params?
      nodes = (Node.create param, @, @depth + 1, 'param' for param in params)
      @children = @children.concat nodes
      @params = @params.concat nodes

    if variable?
      @children.push Node.create variable, @, @depth, 'variable'
    if expressions?
      @children = @children.concat Node.create expression, @, @depth, 'expression' for expression in expressions
    if args?
      @children = @children.concat Node.create arg, @, @depth, 'arg' for arg in args
    if objects?
      @children = @children.concat Node.create object, @, @depth, 'object' for object in objects
    if value?
      @children.push Node.create value, @, @depth, 'value'
    if first?
      @children.push Node.create first, @, @depth, 'first'
    if second?
      @children.push Node.create second, @, @depth, 'second'
    if base?
      if base.value?
        @children.push new BottomNode base, @, @depth, 'base'
      else
        @children.push Node.create base, @, @depth, 'base'
    if name?
      @children.push new BottomNode name, @, @depth, 'name'
    if parent?
      @parentNode.children.push Node.create parent, @, @depth, 'parent'
    if body?
      @children.push Node.create body, @, @depth + 1, 'body'

  find: (range) ->
    for child, i in @children
      nodes = child.find range
      if nodes?.length isnt 0
        return _.compact _.flatten nodes
    []

  bottomUp: (targetNode) ->
    @parentNode.bottomUp targetNode

  topDown: (targetNode) ->
    for child in @children
      child.topDown targetNode

  getIndent: ->
    indent = ''
    depth = @depth
    while depth--
      indent += '.'
    indent

  hasSameValue: (node) ->
    for child in @children
      return true if child.value is node.value
    false

class TopNode extends Node

  constructor: ->
    if Refactor.verbose
      console.log "#{pad '', 15}|#{pad 'SCOPE', 10}|#{@getIndent()}-"
    super

  bottomUp: (targetNode) ->
    for param, i in @params
      if param.hasSameValue targetNode
        return @topDown targetNode
    super

class RootNode extends TopNode

  constructor: ->
    if Refactor.verbose
      console.log pad '', 50, '='
    super

  bottomUp: (targetNode) ->
    @topDown targetNode

class BottomNode extends Node

  constructor: ({ locationData, @value }, @parentNode, @depth, @type) ->
    @range = locationDataToRange locationData
    if Refactor.verbose
      console.log @range + "|#{pad @parentNode.type, 10}|#{@getIndent()}#{@value}"

  find: (range) ->
    return @bottomUp @ if range.isEqual @range

  topDown: (targetNode) ->
    return @ if targetNode isnt @ and targetNode.value is @value
