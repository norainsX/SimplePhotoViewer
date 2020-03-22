//
//  PhotoViewer.swift
//  SimplePhotoViewer
//
//  Created by norains on 2020/3/19.
//  Copyright © 2020 norains. All rights reserved.
//

import SwiftUI

struct PhotoViewer: View {
    var image: UIImage
    var body: some View {
        return GeometryReader { geometryProxy in
            ImageWrapper(image: self.image,
                         frame: CGRect(x: geometryProxy.safeAreaInsets.leading, y: geometryProxy.safeAreaInsets.trailing, width: geometryProxy.size.width, height: geometryProxy.size.height))
        }
    }
}

fileprivate struct ImageWrapper: View {
    // The actual scale base on the minSize
    @State var actualScale: CGFloat = 1.0

    // The actual offset base on the minPosition
    @State var actualOffset: CGPoint = .zero

    // Base on the minScale, the min value is 1
    @State var scaleRatio: CGFloat = 1

    // The image
    private let image: UIImage

    // The frame for the image view
    private let frame: CGRect

    // The value is for draging and zoom gesture
    private let minImgSize: CGSize
    private let maxImgSize: CGSize
    private let minImgDisplayPoint: CGPoint
    private let minScale: CGFloat
    private let maxScale: CGFloat

    init(image: UIImage, frame: CGRect) {
        self.image = image
        self.frame = frame

        var fitRatio: CGFloat = min(frame.width / CGFloat(image.cgImage!.width), frame.height / CGFloat(image.cgImage!.height))
        if fitRatio > 1 {
            fitRatio = 1
        }

        maxImgSize = CGSize(width: CGFloat(image.cgImage!.width),
                            height: CGFloat(image.cgImage!.height))

        minImgSize = CGSize(width: maxImgSize.width * fitRatio,
                            height: maxImgSize.height * fitRatio)

        minImgDisplayPoint = CGPoint(x: (frame.width - minImgSize.width) / 2,
                                     y: (frame.height - minImgSize.height) / 2)

        minScale = fitRatio
        maxScale = min(maxImgSize.width / minImgSize.width, maxImgSize.height / minImgSize.height) * minScale

        print("image size:\(image.cgImage!.width),\(image.cgImage!.height)")
        print("screen:\(frame)")
        print("minImgPoint:\(minImgDisplayPoint)")
    }

    @State private var lastTranslation: CGSize?
    @State private var lastScale: CGFloat?

    // Magnify and Rotate States
    @State private var magScale: CGFloat = 1
    // @State private var rotAngle: Angle = .zero
    @State private var isScaled: Bool = false

    // Drag Gesture Binding
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        let rotateAndZoom = MagnificationGesture()
            .onChanged { scale in
                self.magScale = scale
                self.isScaled = true

                if let lastScale = self.lastScale {
                    // The zoom gesture is base on the center, so is a half
                    let ratio = 1.0 + (scale - lastScale)
                    self.scaleRatio *= ratio
                }

                self.lastScale = scale
            }
            .onEnded { scale in
                scale > 1 ? (self.magScale = scale) : (self.magScale = 1)
                self.isScaled = scale > 1

                if let lastScale = self.lastScale {
                    let ratio = 1.0 + (scale - lastScale)
                    self.scaleRatio *= ratio

                    if self.scaleRatio < 1 {
                        self.scaleRatio = 1
                    } else if self.scaleRatio * self.minScale > self.maxScale {
                        self.scaleRatio = self.maxScale / self.minScale
                    }
                }

                self.lastScale = nil
            }

        let dragOrDismiss = DragGesture()
            .onChanged { value in
                self.dragOffset = value.translation

                if let lastTranslation = self.lastTranslation {
                }

                self.lastTranslation = value.translation
            }
            .onEnded { value in
                if self.isScaled {
                    self.dragOffset = value.translation

                    if let lastTranslation = self.lastTranslation {
                    }

                    self.lastTranslation = nil

                } else {
                    self.dragOffset = CGSize.zero
                }
            }

        let fitToFill = TapGesture(count: 2)
            .onEnded {
                if self.scaleRatio > 1 {
                    self.scaleRatio = 1
                } else {
                    self.scaleRatio = self.maxScale / self.minScale
                }
            }
            .exclusively(before: dragOrDismiss)
            .exclusively(before: rotateAndZoom)

        return Image(uiImage: image)
            // .resizable()
            .renderingMode(.original)
            // .aspectRatio(contentMode: .fit)
            .gesture(fitToFill)
            // .scaleEffect(isScaled ? magScale : max(1 - abs(self.dragOffset.height) * 0.004, 0.6), anchor: .center)
            // .offset(x: dragOffset.width * magScale, y: dragOffset.height * magScale)
            .scaleEffect(minScale * scaleRatio, anchor: .center)
            .offset(x: actualOffset.x, y: actualOffset.y)
            .animation(.spring(response: 0.4, dampingFraction: 0.9))
    }
}
