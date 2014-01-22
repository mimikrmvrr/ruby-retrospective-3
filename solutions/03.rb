module Graphics
  class Canvas
    attr_reader :width, :height

    def initialize(width, height)
      @width = width
      @height = height
      @pixels = Array.new(height*width, :empty)
    end

    def set_pixel(x, y)
      @pixels[y*@width + x] = :full
    end

    def pixel_at?(x, y)
      @pixels[y*@width + x].eql? :full
    end

    def draw(figure)
      figure.draw.each { |x, y| self.set_pixel(x, y) }
    end

    def render_as(renderer)
      visualizer = renderer.visualize
      rows = @pixels.map { |pixel| visualizer[pixel] }.each_slice(@width)
      text = rows.map(&:join).join(visualizer[:end])
      renderer.header + text + renderer.footer
    end
  end

  module Renderers
    class Ascii
      @@visualize = {:full=>"@", :empty=>"-", :end=>"\n"}

      def self.visualize
        @@visualize
      end

      def self.header
        ""
      end

      def self.footer
        ""
      end
    end

    class Html
      def self.visualize
        @@visualize
      end

      def self.header
        @@header
      end

      def self.footer
        @@footer
      end

      @@visualize = {:full=>"<b></b>", :empty=>"<i></i>", :end=>"<br>"}

      @@header = '<!DOCTYPE html>
  <html>
  <head>
    <title>Rendered Canvas</title>
    <style type="text/css">
      .canvas {
        font-size: 1px;
        line-height: 1px;
      }
      .canvas * {
        display: inline-block;
        width: 10px;
        height: 10px;
        border-radius: 5px;
      }
      .canvas i {
        background-color: #eee;
      }
      .canvas b {
        background-color: #333;
      }
    </style>
  </head>
  <body>
    <div class="canvas">'

      @@footer = '</div>
  </body>
  </html>'
    end
  end

  class Point
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def eql?(other)
      @x == other.x and @y == other.y
    end

    def ==(other)
      eql? other
    end

    def <(other)
      @x < other.x || @x == other.x && @y < other.y
    end

    def hash
      [x, y].hash
    end

    def draw
      [[x, y]]
    end
  end

  class Line
    attr_reader :from, :to

    def initialize(from, to)
      from, to = to, from if to < from
      @from = from
      @to = to
    end

    def eql?(other)
      @from == other.from and @to == other.to
    end

    def ==(other)
      eql? other
    end

    def hash
      [from, to].hash
    end

    def draw
      (@from.x - @to.x).abs > (@from.y - @to.y).abs ? draw_by_x : draw_by_y
    end

    private

    def draw_by_x
      delta_x = @to.x - @from.x
      delta_y = @to.y - @from.y
      if delta_x == 0
        return (@from.y).upto(@to.y).map { |y| [@to.x, y] }
      else
        draw_bresenham(@from.x, @to.x, delta_y / delta_x.to_f, @from.y, :x)
      end
    end

    def draw_bresenham(from, to, delta_e, coordinate, x_or_y)
      error, coordinates = 0, []
      from.upto(to).each do |x|
        error = error + delta_e
        coordinates << (x_or_y == :x ? [x, coordinate] : [coordinate, x])
        coordinate, error = calculate_coordinate_error coordinate, error
      end
      coordinates
    end

    def calculate_coordinate_error(coordinate, error)
      if error >= 0.5
        [coordinate + 1, error - 1]
      elsif error <= - 0.5
        [coordinate - 1, error + 1]
      else
        [coordinate, error]
      end
    end

    def draw_by_y
      delta_x = @to.x - @from.x
      delta_y = @to.y - @from.y
      if delta_y == 0
        return (@from.x).upto(@to.x).map { |x| [x, @to.y] }
      else
        from, to = @from.y > @to.y ?  [@to, @from] : [@from, @to]
        draw_bresenham(from.y, to.y, delta_x / delta_y.to_f, from.x, :y)
      end
    end
  end

  class Rectangle
    attr_reader :left, :right

    def initialize(left, right)
      left, right = right, left if right < left
      @left = left
      @right = right
    end

    def top_left
      x = @left.x
      y = [@left.y, @right.y].min
      Point.new x, y
    end

    def top_right
      x = @right.x
      y = [@left.y, @right.y].min
      Point.new x, y
    end

    def bottom_left
      x = @left.x
      y = [@left.y, @right.y].max
      Point.new x, y
    end

    def bottom_right
      x = @right.x
      y = [@left.y, @right.y].max
      Point.new x, y
    end

    def eql?(other)
      bottom_left == other.bottom_left and top_right == other.top_right
    end

    alias_method :==, :eql?

    def hash
      [top_right, bottom_left].hash
    end

    def draw
      Line.new(top_left, top_right).draw
                                   .concat(Line.new(top_left, bottom_left).draw)
                                   .concat(Line.new(bottom_left, bottom_right).draw)
                                   .concat(Line.new(bottom_right, top_right).draw)
    end
  end
end