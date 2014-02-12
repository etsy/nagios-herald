import os
from PIL import ImageFont

def get_width_for_font_size(draw, font_type, font_size, label):
    font = ImageFont.truetype(font_type, font_size)
    return draw.textsize(label, font=font)

def get_optimal_font_size(draw, font_type, max_width, max_height, label, min_font_size, font_size = 100):
    """ Find the maximum font_size given a label to display in a max_width, using a font_type """
    if font_size < min_font_size:
        return None

    font = ImageFont.truetype(font_type, font_size)
    label_width, label_height = draw.textsize(label, font=font)
    if label_width < max_width and label_height < max_height:
        return font_size
    else:
        return get_optimal_font_size(draw, font_type, max_width, max_height, label, min_font_size, font_size -1)

def get_font(font_name):
  font_path = os.path.join(os.path.dirname(__file__), 'pilfonts', font_name)
  if os.path.isfile(font_path):
      return font_path
  else:
      raise Exception("Font %s not found" % font_name)
