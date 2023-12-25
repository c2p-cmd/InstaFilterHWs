//
//  EditingView.swift
//  InstafilterHWS
//
//  Created by Sharan Thakur on 25/12/23.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import SwiftUI

struct EditingView: View {
    @State private var processedImage: Image?
    
    @State private var selectedItem: PhotosPickerItem?
    
    @State private var intensity: Float = 0.5
    @State private var radius: Float = 30
    @State private var scale: Float = 5.0
    
    @State private var currentFilter: CIFilter = .colorMonochrome()
    
    @State private var showFilterDialog = false
    
    @State private var imageRotation: Angle = .degrees(0)
    
    private let ciContext = CIContext()
    
    var body: some View {
        VStack {
            if let processedImage {
                GeometryReader { geometry in
                    let size = geometry.size
                    
                    ScrollView {
                        choseImageView(processedImage: processedImage)
                            .frame(width: size.width, height: size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            } else {
                photosPicker {
                    ContentUnavailableView(
                        "No Photo",
                        systemImage: "photo.badge.plus",
                        description: Text("Tap to import a photo")
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding([.horizontal, .bottom])
    }
    
    var disableFilter: Bool {
        currentFilter.inputKeys.filter { !$0.contains("inputImage") }.isEmpty
    }
}

// MARK: - views
extension EditingView {
    func photosPicker(@ViewBuilder labelBuilder: () -> some View) -> some View {
        PhotosPicker(selection: $selectedItem, label: labelBuilder)
            .onChange(of: selectedItem, loadImage)
    }
    
    @ViewBuilder
    func choseImageView(processedImage: Image) -> some View {
        Text("Current Filter: \(currentFilter.shortName)")
            .font(.title3)
            .fontWeight(.bold)
            .fontDesign(.rounded)
        
        Spacer()
        
        processedImage
            .resizable()
            .scaledToFit()
            .transition(.slide)
            .rotationEffect(imageRotation, anchor: .center)
            .toolbar {
                ShareLink(
                    item: processedImage,
                    preview: SharePreview(
                        "Instafilter Image",
                        image: processedImage,
                        icon: Image(systemName: "photo.artframe")
                    )
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        
        Spacer()
        
        // filter customization
        filterSliders()
            .fontDesign(.monospaced)
        
        // toolbar
        HStack {
            Button(action: changeFilter) {
                Text("Change Filter")
            }
            .confirmationDialog(
                "Select New Filter",
                isPresented: $showFilterDialog,
                titleVisibility: .visible,
                actions: filtersDialog
            )
            
            Spacer()
            
            photosPicker {
                Text("Change Image")
            }
            
            Spacer()
            
            Button("Rotate", systemImage: "rotate.right") {
                withAnimation {
                    imageRotation += .degrees(90)
                }
            }
        }
        .fontWeight(.semibold)
        .tint(.mint)
        .buttonStyle(.bordered)
        .fontDesign(.monospaced)
    }
    
    @ViewBuilder
    func filterSliders() -> some View {
        if currentFilter.inputKeys.contains(kCIInputIntensityKey) {
            HStack {
                Text("Intensity:")
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Slider(
                    value: $intensity,
                    in: 0.0...1.0,
                    label: {
                        
                    },
                    minimumValueLabel: {
                        Text("0%")
                    },
                    maximumValueLabel: {
                        Text("100&")
                    }
                )
                .font(.caption)
                .onChange(of: intensity, applyFilter)
            }
        }
        
        if currentFilter.inputKeys.contains(kCIInputRadiusKey) {
            HStack {
                Text("Radius:")
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Slider(
                    value: $radius,
                    in: 0.0...90.0,
                    label: {
                        
                    },
                    minimumValueLabel: {
                        Text("0°")
                    },
                    maximumValueLabel: {
                        Text("90°")
                    }
                )
                .font(.caption)
                .onChange(of: radius, applyFilter)
            }
        }
        
        if currentFilter.inputKeys.contains(kCIInputScaleKey) {
            HStack {
                Text("Scale:")
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Slider(
                    value: $scale,
                    in: 0.0...100.0,
                    label: {
                        
                    },
                    minimumValueLabel: {
                        Text("0")
                    },
                    maximumValueLabel: {
                        Text("100")
                    }
                )
                .font(.caption)
                .onChange(of: scale, applyFilter)
            }
        }
    }
    
    @ViewBuilder
    func filtersDialog() -> some View {
        Button("Monochrome") { setFilter(newFilter: .photoEffectMono()) }
        Button("Color Monochrome") { setFilter(newFilter: .colorMonochrome()) }
        Button("Sepia") { setFilter(newFilter: .sepiaTone()) }
        Button("Crystallize") { setFilter(newFilter: .crystallize()) }
        Button("Pixellate") { setFilter(newFilter: .pixellate()) }
        Button("Edges") { setFilter(newFilter: .edges()) }
        Button("Boom") { setFilter(newFilter: .bloom()) }
        Button("Unsharp Mask") { setFilter(newFilter: .unsharpMask()) }
        Button("Bokeh Blur") { setFilter(newFilter: .bokehBlur()) }
        Button("Gaussian Blur") { setFilter(newFilter: .gaussianBlur()) }
        Button("Vignette") { setFilter(newFilter: .vignette()) }
        Button("Comic Effect") { setFilter(newFilter: .comicEffect()) }
        Button("Color Invert") { setFilter(newFilter: .colorInvert()) }
        Button("Gloom") { setFilter(newFilter: .gloom()) }
        
        // Cancel button
        Button("Cancel", role: .cancel) {
            showFilterDialog = false
        }
    }
}

// MARK: - image filter functions
extension EditingView {
    func changeFilter() {
        showFilterDialog = true
    }
    
    func setFilter(newFilter: CIFilter) {
        currentFilter = newFilter
#if DEBUG
        print(currentFilter.inputKeys.description)
#endif
        loadImage()
    }
    
    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self),
                  let inputImage = UIImage(data: imageData)
            else {
                return
            }
            
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyFilter()
        }
    }
    
    func applyFilter() {
        currentFilter.setValueIfAvailable(intensity, forKey: kCIInputIntensityKey)
        currentFilter.setValueIfAvailable(radius, forKey: kCIInputRadiusKey)
        currentFilter.setValueIfAvailable(scale, forKey: kCIInputScaleKey)
        
        guard let outputImage = currentFilter.outputImage
        else {
            return
        }
        
        guard let cgImage = ciContext.createCGImage(outputImage, from: outputImage.extent)
        else {
            return
        }
        
        let uiImage = UIImage(cgImage: cgImage)
        withAnimation(.bouncy) {
            processedImage = Image(uiImage: uiImage)
        }
    }
}

#Preview {
    NavigationStack {
        EditingView()
            .preferredColorScheme(.light)
    }
}
