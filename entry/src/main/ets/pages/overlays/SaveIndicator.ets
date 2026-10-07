@Component
export struct SaveIndicator {
  @Prop screenW: number = 360;

  build() {
    Text('已保存')
      .fontSize(12)
      .fontWeight(FontWeight.Bold)
      .fontColor('#22c55e')
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor('rgba(0,0,0,0.7)')
      .borderRadius(6)
      .position({ x: this.screenW - 80, y: 50 })
      .opacity(0.9)
  }
}
