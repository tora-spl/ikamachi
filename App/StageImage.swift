import SwiftUI
import IkaMachiKit

/// commons由来のステージ画像。バンドルのCommons/stagesフォルダ参照から読む。
struct StageImage: View {
    let stageID: Int

    var body: some View {
        if let image = Self.uiImage(forVsStageId: stageID) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                Rectangle().fill(.quaternary)
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
    }

    static func uiImage(forVsStageId id: Int) -> UIImage? {
        guard let commonsID = StageCatalog.shared.commonsID(forVsStageId: id),
              let url = Bundle.main.url(forResource: commonsID, withExtension: "png",
                                        subdirectory: "Commons/stages") else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
}
