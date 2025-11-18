require "rayzer"

x = 0
y = 0
width = 100
height = 100

# Create a new top-level layout
root = Rayzer::Layout.new(x, y, width, height)

# Create 3 sections with fixed length 10, minimum length 0 and another fixed length 10.
sections = %w[ 10 >=0 10 ]

# You can optionally name the sections. If given a name, the section can be accessed with the reader of the same name.
section_names = %w[ header main footer ]

# Split_to_* returns the children as well also yields them to the block for further partition if a block is given.
root.split_to_rows!(sections, section_names) do |header, main, footer|

  # Percentage constraint
  constraints = %w[ 30% ]
 
  # If there is remaining space after all constraints are satisfied, split_to_* appends the remaining to the children, whereas the bang version raises Rayzer::Layout::RemainingSpaceError.
  # 
  # The remaining is also accessable using the remaining method.
  #
  # When no names are given, you can only access them using the children attr_reader later
  main.split_to_cols(constraints) do |sidebar, remaining|

    # Ratio constraints
    rows = %i[:1 :3 :1]

    # If you only want to access some inner layout by name, use a hash with index as the key and a symbol or name as value.
    row_names = { 1 => :content }

    remaining.split_to_rows!(rows, row_names)
  end
end


p root.header.rect                       # [0, 0, 100, 10]   
p root.main.rect                         # [0, 10, 100, 80]      
p root.footer.rect                       # [0, 90, 100, 10]      
p root.main.children[0].rect             # [0, 10, 30.0, 80]            
p root.main.remaining.rect               # [30.0, 10, 70.0, 80]      
p root.main.remaining.children[0].rect   # [30.0, 10, 70.0, 16.0]        
p root.main.remaining.content.rect       # [30.0, 26.0, 70.0, 48.0]      
p root.main.remaining.children[2].rect   # [30.0, 74.0, 70.0, 16.0]           
