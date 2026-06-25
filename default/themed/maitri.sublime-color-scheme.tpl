{
  "name": "maitri",
  "author": "maitri",
  "variables": {},
  "globals": {
    "background": "{{ background }}",
    "foreground": "{{ foreground }}",
    "caret": "{{ cursor }}",
    "line_highlight": "{{ color0 }}",
    "selection": "{{ selection_background }}",
    "selection_foreground": "{{ selection_foreground }}",
    "gutter": "{{ background }}",
    "gutter_foreground": "{{ color8 }}",
    "accent": "{{ accent }}"
  },
  "rules": [
    { "scope": "comment", "foreground": "{{ color8 }}", "font_style": "italic" },
    { "scope": "string", "foreground": "{{ color2 }}" },
    { "scope": "constant.numeric", "foreground": "{{ color3 }}" },
    { "scope": "constant.language", "foreground": "{{ color3 }}" },
    { "scope": "keyword", "foreground": "{{ color5 }}" },
    { "scope": "storage.type", "foreground": "{{ color4 }}" },
    { "scope": "entity.name.function", "foreground": "{{ color4 }}" },
    { "scope": "variable", "foreground": "{{ foreground }}" },
    { "scope": "entity.name.tag", "foreground": "{{ color1 }}" },
    { "scope": "support.type, support.class", "foreground": "{{ color6 }}" }
  ]
}
