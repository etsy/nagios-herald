import os
from PIL import Image, ImageDraw
from stackbar import Stackbar
from chart_utils import get_optimal_font_size, get_font, get_width_for_font_size

class GroupedStackbars:
    def __init__(self, options = {}):

        self.options =  options

        self.width = options.get('width', 500)
        assert self.width > 0, "width must be > 0"

        self.bar_area_ratio = options.get('bar_area_ratio', .65)
        assert self.bar_area_ratio <=1, "bar_area_ration must be <= 1"

        self.bar_height_ratio = options.get('bar_height_ratio', .2)
        assert self.bar_height_ratio <=1, "bar_height_ratio must be <= 1"

        self.font_type = options.get('font_type', get_font('arial_black.ttf'))
        self.min_font_size = 15

        self.img = None
        self.draw = None

        self.stack_bars = []

    def initializeDims(self, data, optimize_bar_area_width = True):
        self.bars_width = int(self.bar_area_ratio * self.width)
        self.bar_height = int(self.bar_height_ratio * self.bars_width)
        self.height = len(data) * self.bar_height

        self.img = Image.new('RGBA', (self.width, self.height), (255, 255, 255))
        self.draw = ImageDraw.Draw(self.img)

        longest_label = self.get_longest_label(data)
        optimal_font_size = get_optimal_font_size(
            self.draw,
            self.font_type,
            self.width -self.bars_width,
            self.bar_height,
            longest_label,
            self.min_font_size
        )

        if not optimal_font_size and optimize_bar_area_width:
            # we did not find an optimal font size - shrink the bar area to find an acceptable font size
            label_width, label_height = get_width_for_font_size(self.draw, self.font_type, self.min_font_size, longest_label)
            new_bar_width = self.width - label_width - 3 #3 is some right border
            bar_width = max(0.3 * self.width, new_bar_width)
            self.bar_area_ratio = float(bar_width) / float(self.width)
            self.initializeDims(data, False)

        self.font_size = optimal_font_size or self.min_font_size

    def get_longest_label(self, data):
        # One liner for python 2.6 and above
        #longest_legend = reduce(lambda x, y: x if len(x) < len(y) else y, data)[0]
        longest_label = ""
        for i in data:
            label = i[0]
            if len(label) > len(longest_label):
                longest_label = label
        return longest_label

    def initiliazeStackBars(self, data):
        self.stack_bars = []
        # get the dimensions for the gauges area and for the text area
        for label, value in data:
            sb = Stackbar(self.draw, label, value, self.options)
            self.stack_bars.append(sb)

    def renderStackBars(self):
        offset = 0
        for i, sb in enumerate(self.stack_bars):
            draw_bottom_border = i == (len(self.stack_bars) - 1)
            sb.render(self.width, offset, self.bars_width, self.bar_height, self.font_size, draw_bottom_border)
            offset += self.bar_height

    def render(self, data):
        if not data:
            return

        # Initialize the drawing area
        self.initializeDims(data)

        # Create new stack bars
        self.initiliazeStackBars(data)

        # render each gauge according to the optimal dims
        self.renderStackBars()

        return self.img

    def save(self, path):
        self.img.save(path)
        print "image saved as %s" % path
