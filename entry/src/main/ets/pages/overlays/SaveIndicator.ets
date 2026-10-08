@Component
export struct SaveIndicator {
  @Prop screenW: number = 360;

  build() {
    Text('已保存')
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor('#22c55e')
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor('#0a0a15e0')
      .borderRadius(6)
      .border({ width: 1, color: '#22c55e60' })
      .position({ x: this.screenW - 80, y: 50 })
  }
}
