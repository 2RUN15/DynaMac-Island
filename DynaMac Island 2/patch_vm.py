import re

with open("ViewModels/IslandViewModel.swift", "r") as f:
    text = f.read()

# Replace isExpanded logic so it opens anytime when hovered
text = text.replace('    var isExpanded: Bool {\n        return isHovered && hasActiveMusic\n    }', 
                    '    var isExpanded: Bool {\n        return isHovered\n    }')

# Inject calendar layer
injection = """    // Takvim mantığı
    @Published var calendarEvents: [CalendarEvent] = []
    private var calendarService = CalendarService()
    
    var hasActiveMusic: Bool {"""

text = text.replace("    var hasActiveMusic: Bool {", injection)

init_injection = """        self.calendarService.$upcomingEvents
            .receive(on: RunLoop.main)
            .assign(to: \\.calendarEvents, on: self)
            .store(in: &cancellables)
            
        calculateNotchDimensions()"""

text = text.replace("        calculateNotchDimensions()", init_injection)

with open("ViewModels/IslandViewModel.swift", "w") as f:
    f.write(text)
