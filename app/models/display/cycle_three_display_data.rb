module Display
  class CycleThreeDisplayData < DisplayData
    def prefix
      'cycle3'
    end

    content :name
    content :field_name
    content :help_to_find
    content :example
  end
end
