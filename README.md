# Skin Lesion Segmentation App

A MATLAB-based interactive GUI application for segmenting lesions in medical images using **CIELuv color space** analysis and **Euclidean distance-based thresholding**.

## 🧠 Features

- 📷 Upload RGB medical images (`.jpg`, `.png`, `.bmp`)
- 🌈 Convert to **CIELuv** color space for perceptually uniform color analysis
- 🟩 Automatically generate an **initial domain (seed)** mask
- 📏 Compute **Euclidean distance** from seed region's average color
- ✂️ Perform **segmentation** using thresholding and morphological operations
- 👁️ View the final **segmented lesion** masked over the original image
- 📊 Step-by-step visual feedback using 6-panel display

## 🛠️ How It Works

1. **Upload Image**  
   Load a lesion-containing image via file browser.

2. **Convert to CIELuv**  
   Converts the RGB image to CIELuv for better color discrimination.

3. **Select Initial Domain**  
   A central region is chosen as the "seed" for lesion detection.

4. **Compute Euclidean Distance**  
   Measures distance from each pixel to the mean color of the seed.

5. **Segment the Lesion**  
   Thresholds the distance map and applies morphological refinements.

6. **Visualize the Result**  
   Final mask is applied to original image to isolate the lesion.

## 🧪 Visual Pipeline

```
[ Original ] → [ CIELuv (L*) ] → [ Domain Mask ]  
     ↓                  ↓                  ↓  
[ Distance Map ] → [ Segmentation Mask ] → [ Final Segmented Lesion ]
```

## 📦 Requirements

- MATLAB (R2018b or later recommended)
- Image Processing Toolbox

## 🚀 Getting Started

1. Clone the repository or download the source files.

```bash
git clone https://github.com/yourusername/lesion-segmentation-app.git
```

2. Open `LesionSegmentationApp.m` in MATLAB.

3. Run the function:

```matlab
LesionSegmentationApp
```

4. Use the interactive GUI to process images.

## 📁 Folder Structure

```
lesion-segmentation-app/
├── SkinCancer_Test_Images
├── LesionSegmentationApp.m      % Main application code
└── README.md                    % This file
```

## 📸 Screenshots

*You can add some screenshots of your GUI here to showcase each step.*

## 🧑‍💻 Author

**Your Name**  
[GitHub](https://github.com/yourusername) • [LinkedIn](https://linkedin.com/in/yourprofile)

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

Let me know if you want this README styled with badges, images, or installation instructions for MATLAB runtimes or packaged apps!
