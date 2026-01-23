//
//  ZbWidgetBundle.swift
//  ZbWidget
//
//  Created by Ali Waseem on 2025-03-11.
//

import SwiftUI
import WidgetKit

// MARK: - Contract & Notes
//
// 职责：
// - 聚合 Widget 与 Live Activity 入口；具体小组件在 Providers/Widgets 内定义；
// - 通过 App Group (UserDefaults suite) 读取 SharedData 快照，展示轻量状态；
// - 通过 App Intents/URL Scheme 触发主 App 的“后台启动/停止”入口。
//
// 与主 App 的契约：
// - 主 App 的“状态同步网关”负责刷新快照并触发 `WidgetCenter.reloadTimelines()`；
// - Widget 自身避免写入业务状态，仅作为只读视图与触发器。

@main
struct ZbWidgetBundle: WidgetBundle {
  var body: some Widget {
    ProfileControlWidget()
    ZbWidgetLiveActivity()
  }
}
