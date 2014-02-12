import os
from PIL import ImageFont
from chart_utils import get_optimal_font_size, get_font

class Stackbar:
    def __init__(self, draw, legend, fill_value, options = {}):

        assert fill_value <= 100, "Invalid fill value - must be <= 100"

        self.legend = legend
        self.fill_value = fill_value

        self.border = options.get('bar_border', 1)
        self.full_color = options.get('green', (255, 0, 0))
        self.empty_color = options.get('red', (0, 255, 0))
        self.font_type = options.get('font_type', get_font('arial_black.ttf'))

        self.light_font_color = options.get('fontcolor', (255, 255, 255))
        self.dark_font_color = options.get('fontcolor', (0, 0, 0))

        self.draw = draw

    def drawFullRectangle(self, width, bar_height, height_offset, font_size, bottom_border_offset):


        rect_width = self.fill_value * width / 100.
        full_top_left = (self.border, self.border + height_offset)
        full_bottom_right = (rect_width, height_offset + bar_height - self.border - bottom_border_offset)
        self.draw.rectangle((full_top_left, full_bottom_right), fill=self.full_color)

        # Draw text
        rect_label = "%i%%" % self.fill_value
        optimal_font_size = get_optimal_font_size(self.draw, self.font_type, rect_width, bar_height, rect_label, 7, font_size)
        if not optimal_font_size:
            return

        font = ImageFont.truetype(self.font_type, optimal_font_size)
        label_width, label_height = self.draw.textsize(rect_label, font=font)
        label_margin = (rect_width - label_width) / 2
        label_offset = (bar_height - label_height) / 2
        self.draw.text(
            (self.border + 1 + label_margin, height_offset + self.border + 1 + label_offset),
            rect_label,
            font=font,
            fill=self.light_font_color
        )

    def drawEmptyRectangle(self, width, bar_height, height_offset, font_size, bottom_border_offset):
        rect_start = self.fill_value * width / 100.
        rect_width = width - rect_start

        empty_top_left = (rect_start + self.border + 1, self.border + height_offset)
        empty_bottom_right = (width - self.border, height_offset + bar_height - self.border -bottom_border_offset)

        self.draw.rectangle((empty_top_left, empty_bottom_right), fill=self.empty_color)

        rect_label = "%i%%" % (100 - self.fill_value)
        optimal_font_size = get_optimal_font_size(self.draw, self.font_type, rect_width, bar_height, rect_label, 7, font_size)
        if not optimal_font_size:
            return

        font = ImageFont.truetype(self.font_type, optimal_font_size)
        label_width, label_height = self.draw.textsize(rect_label, font=font)
        label_margin = rect_start + (rect_width - label_width) / 2
        label_offset = (bar_height - label_height) / 2
        self.draw.text(
            (label_margin, height_offset + self.border + 1 + label_offset),
            rect_label,
            font=font,
            fill=self.dark_font_color
        )

    def drawLegend(self, width_offset, bar_height, height_offset, font_size):
        font = ImageFont.truetype(self.font_type, font_size)
        label_width, label_height = self.draw.textsize(self.legend, font=font)
        label_margin = width_offset + 2 #some left padding
        label_offset = (bar_height - label_height) / 2
        self.draw.text(
            (label_margin, height_offset + self.border + 1 + label_offset),
            self.legend,
            font=font,
            fill=self.dark_font_color
        )

    def drawBase(self, width, bar_height, height_offset):
        self.draw.rectangle((0,height_offset, width, height_offset + bar_height), fill=(0,0,0))

    def render(self, width, height_offset, bars_width, bar_height, font_size, draw_bottom_border = True):
        if draw_bottom_border:
            bottom_border_offset = 1
        else:
            bottom_border_offset = 0

        self.drawBase(bars_width, bar_height, height_offset)

        self.drawFullRectangle(bars_width, bar_height, height_offset, font_size - 1, bottom_border_offset)

        self.drawEmptyRectangle(bars_width, bar_height, height_offset, font_size - 1, bottom_border_offset)

        self.drawLegend(bars_width, bar_height, height_offset, font_size)
