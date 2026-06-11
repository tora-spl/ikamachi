import WidgetKit
import SwiftUI

@main
struct IkaMachiWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextMatchWidget()
        ScheduleListWidget()
    }
}
