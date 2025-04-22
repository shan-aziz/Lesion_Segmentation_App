function LesionSegmentationApp()
    % This function sets up a GUI for basic lesion segmentation
    % using color space analysis and Euclidean distance.

    % Create the main application figure window
    % Set its name and initial position, then maximize it
    mainFigure = uifigure('Name', 'Lesion Segmentation Demo', 'Position', [100, 100, 900, 600]);
    mainFigure.WindowState = 'maximized'; % Set window state to maximized

    % --- Add a Main Title Label at the Top ---
    % This label provides the overall title for the application window.
    appTitleLabel = uilabel(mainFigure, 'Position', [300, 570, 300, 30], ...
        'Text', 'Lesion Segmentation App', 'FontSize', 24, ...
        'HorizontalAlignment', 'center'); % Center the text within the label

    % --- Create User Interface (UI) Components (Buttons) ---
    % These buttons trigger the different steps of the segmentation process.
    % Position adjusted slightly downwards to make space for the title.

    % Button to upload an image file
    imageUploadButton = uibutton(mainFigure, 'push', 'Position', [20, 520, 150, 30], ...
        'Text', 'Upload Image', 'FontSize', 14, ...
        'ButtonPushedFcn', @(btn,event) uploadImage()); % Callback function

    % Button to convert the image to CIELuv color space
    cieluvConvertButton = uibutton(mainFigure, 'push', 'Position', [180, 520, 150, 30], ...
        'Text', 'CIELuv Color Space', 'FontSize', 14, ...
        'ButtonPushedFcn', @(btn,event) applyCIELuv()); % Callback function

    % Button to define an initial domain (seed area)
    initialDomainButton = uibutton(mainFigure, 'push', 'Position', [340, 520, 150, 30], ...
        'Text', 'Initial Domain', 'FontSize', 14, ...
        'ButtonPushedFcn', @(btn,event) createDomain()); % Callback function

    % Button to calculate Euclidean distance in CIELuv space from the domain mean
    euclideanDistanceButton = uibutton(mainFigure, 'push', 'Position', [500, 520, 150, 30], ...
        'Text', 'Euclidean Distance', 'FontSize', 14, ...
        'ButtonPushedFcn', @(btn,event) calculateEuclideanDistance()); % Callback function

    % Button to perform the final segmentation based on distance
    segmentationProcessButton = uibutton(mainFigure, 'push', 'Position', [660, 520, 150, 30], ...
        'Text', 'Final Segmentation', 'FontSize', 14, ...
        'ButtonPushedFcn', @(btn,event) finalSegmentation()); % Callback function

    % Button to display the original image masked by the segmentation result
    displaySegmentedLesionButton = uibutton(mainFigure, 'push', 'Position', [820, 520, 150, 30], ...
        'Text', 'Segmented Lesion', 'FontSize', 14, ...
        'ButtonPushedFcn', @(btn,event) showSegmentedLesion()); % Callback function

    % --- Create Axes for Displaying Images ---
    % Six axes are created in a 2x3 grid to show the different processing steps.
    % All axes are given the same relative size and positioned on the figure.

    axesOriginalImage = axes(mainFigure, 'Position', [0.05, 0.4, 0.25, 0.25]); % Top-left axes
    axesCieluvImage = axes(mainFigure, 'Position', [0.35, 0.4, 0.25, 0.25]); % Top-center axes
    axesDomainOverlay = axes(mainFigure, 'Position', [0.65, 0.4, 0.25, 0.25]); % Top-right axes
    axesDistanceMap = axes(mainFigure, 'Position', [0.05, 0.05, 0.25, 0.25]); % Bottom-left axes
    axesSegmentationMask = axes(mainFigure, 'Position', [0.35, 0.05, 0.25, 0.25]); % Bottom-center axes
    axesSegmentedResult = axes(mainFigure, 'Position', [0.65, 0.05, 0.25, 0.25]); % Bottom-right axes

    % --- Variables to Store Data ---
    % These variables will hold the image data and intermediate results
    % throughout the segmentation process. Initialized as empty.
    originalRGBImage = [];       % Stores the image loaded by the user
    cieluvImage = [];            % Stores the image converted to CIELuv color space
    initialDomainMask = [];      % Stores a binary mask defining the initial seed area
    euclideanDistanceMap = [];   % Stores the map of Euclidean distances in CIELuv space
    segmentationFinalMask = [];  % Stores the final binary mask after segmentation
    resultSegmentedImage = [];   % Stores the result of applying the final mask to the original image

    % --- Button Callback Functions ---
    % These nested functions are executed when the corresponding buttons are pushed.

    % Function to handle image upload
    function uploadImage()
        % Open a file dialog to select an image file (jpg, png, bmp)
        [selectedFileName, selectedFilePath] = uigetfile('*.jpg;*.png;*.bmp', 'Select an Image');

        % Check if the user cancelled the dialog
        if isequal(selectedFileName, 0)
            return; % Exit the function if no file was selected
        end

        % Construct the full file path
        fullFileAndPath = fullfile(selectedFilePath, selectedFileName);

        % Read the selected image into the originalRGBImage variable
        originalRGBImage = imread(fullFileAndPath);

        % Display the original image in the top-left axes
        imshow(originalRGBImage, 'Parent', axesOriginalImage);
        title(axesOriginalImage, 'Original Image'); % Add a title to the axes
    end

    % Function to convert the loaded image to CIELuv color space
    function applyCIELuv()
        % Check if an image has been uploaded first
        if isempty(originalRGBImage)
            uialert(mainFigure, 'Please upload an image first.', 'Error', 'Icon', 'error');
            return; % Exit if no image is loaded
        end

        % Convert RGB color space to XYZ color space
        srgbToXyzTransform = makecform('srgb2xyz'); % Create the conversion structure
        xyzColorImage = applycform(originalRGBImage, srgbToXyzTransform); % Apply the conversion

        % Convert XYZ color space to CIELuv color space (MATLAB uses uvl ordering)
        xyzToLuvTransform = makecform('xyz2uvl'); % Create the conversion structure
        cieluvImage = applycform(xyzColorImage, xyzToLuvTransform); % Apply the conversion

        % Display the L* (lightness) channel of the CIELuv image
        % The L* channel is the first channel (:,:,1)
        imshow(cieluvImage(:,:,1), [], 'Parent', axesCieluvImage); % [] scales the intensity range
        title(axesCieluvImage, 'CIELuv Color Space (L channel)'); % Add a title
    end

    % Function to create an initial domain (seed) mask
    % This mask defines a central region assumed to contain the lesion (or seed point).
    function createDomain()
        % Check if the CIELuv image is available
        if isempty(cieluvImage)
            uialert(mainFigure, 'Please apply CIELuv color space first.', 'Error', 'Icon', 'error');
            return; % Exit if CIELuv conversion hasn't been done
        end

        % Get the dimensions (rows and columns) of the image
        [imageRows, imageColumns, ~] = size(cieluvImage);

        % --- Define the Initial Domain Region ---
        % This creates a rectangular region around the center of the image.

        % Calculate the center row and column
        imageCenterRow = round(imageRows / 2);
        imageCenterColumn = round(imageColumns / 2);

        % Determine the size of the domain rectangle
        % It's 20% of the smaller image dimension (rows or columns)
        initialDomainSize = round(min(imageRows, imageColumns) * 0.2);

        % Calculate the row range for the domain, ensuring it stays within image bounds
        domainRowRange = max(1, imageCenterRow - initialDomainSize):min(imageRows, imageCenterRow + initialDomainSize);

        % Calculate the column range for the domain, ensuring it stays within image bounds
        domainColumnRange = max(1, imageCenterColumn - initialDomainSize):min(imageColumns, imageCenterColumn + initialDomainSize);

        % Create a binary mask initialized to false (all pixels are not in the domain)
        initialDomainMask = false(imageRows, imageColumns);

        % Set the pixels within the calculated row and column ranges to true (in the domain)
        initialDomainMask(domainRowRange, domainColumnRange) = true;

        % --- Display the Domain Overlay ---
        % Show the original image with the created domain region highlighted.

        % Display the original image in the top-right axes
        imshow(originalRGBImage, 'Parent', axesDomainOverlay);

        % Keep the current image in the axes while adding more elements
        hold(axesDomainOverlay, 'on');

        % Create a red overlay image the same size as the original image
        redOverlayForDomain = cat(3, ones(imageRows, imageColumns), zeros(imageRows, imageColumns), zeros(imageRows, imageColumns));

        % Display the red overlay on top of the original image
        % Store the handle of the overlay image
        overlayHandle = imshow(redOverlayForDomain, 'Parent', axesDomainOverlay);

        % Set the transparency (AlphaData) of the overlay based on the domain mask
        % The mask region (true values) will be partially opaque (0.3 alpha)
        set(overlayHandle, 'AlphaData', 0.3 * initialDomainMask);

        % Add a title to the axes
        title(axesDomainOverlay, 'Initial Domain (Red Overlay)');

        % Release the hold on the axes
        hold(axesDomainOverlay, 'off');
    end

    % Function to calculate the Euclidean distance of each pixel
    % from the mean color of the initial domain in CIELuv space.
    function calculateEuclideanDistance()
        % Check if the initial domain mask is available
        if isempty(initialDomainMask)
            uialert(mainFigure, 'Please create the initial domain first.', 'Error', 'Icon', 'error');
            return; % Exit if the domain hasn't been defined
        end

        % Get the dimensions of the CIELuv image
        [imageRows, imageColumns, ~] = size(cieluvImage);

        % Extract the L, u, and v channels from the CIELuv image
        luvLChannel = cieluvImage(:,:,1);
        luvUChannel = cieluvImage(:,:,2);
        luvVChannel = cieluvImage(:,:,3);

        % --- Calculate Color Statistics within the Domain ---

        % Get the pixel values within the initial domain mask for each channel
        domainLValues = luvLChannel(initialDomainMask);
        domainUValues = luvUChannel(initialDomainMask);
        domainVValues = luvVChannel(initialDomainMask);

        % Calculate the mean value for each channel within the domain
        domainMeanL = mean(domainLValues(:)); % Use (:) to ensure it treats it as a column vector
        domainMeanU = mean(domainUValues(:));
        domainMeanV = mean(domainVValues(:));

        % --- Calculate Euclidean Distance for Each Pixel ---

        % Initialize a matrix to store the distance map
        euclideanDistanceMap = zeros(imageRows, imageColumns);

        % Loop through each pixel (row by row, column by column)
        for rowIndex = 1:imageRows
            for columnIndex = 1:imageColumns
                % Calculate the Euclidean distance between the current pixel's color
                % (L(i,j), u(i,j), v(i,j)) and the domain's mean color (meanL, meanu, meanv)
                euclideanDistanceMap(rowIndex, columnIndex) = sqrt((luvLChannel(rowIndex, columnIndex) - domainMeanL)^2 + ...
                                                                    (luvUChannel(rowIndex, columnIndex) - domainMeanU)^2 + ...
                                                                    (luvVChannel(rowIndex, columnIndex) - domainMeanV)^2);
            end
        end

        % --- Display the Distance Map ---

        % Display the calculated distance map in the bottom-left axes
        imshow(euclideanDistanceMap, [], 'Parent', axesDistanceMap); % [] scales display range
        colormap(axesDistanceMap, jet); % Apply the 'jet' colormap
        colorbar(axesDistanceMap); % Add a color bar to indicate distance values
        title(axesDistanceMap, 'Euclidean Distance Map'); % Add a title
    end

    % Function to perform the final segmentation based on the distance map.
    % This involves thresholding and morphological operations.
    function finalSegmentation()
        % Check if the distance map has been calculated
        if isempty(euclideanDistanceMap)
            uialert(mainFigure, 'Please calculate the Euclidean distance first.', 'Error', 'Icon', 'error');
            return; % Exit if distance map is not available
        end

        % --- Create Initial Mask based on Distance Threshold ---

        % Calculate an automatic threshold using Otsu's method on the distance map
        segmentationThreshold = graythresh(euclideanDistanceMap);

        % Create a binary mask: pixels with distance <= scaled threshold are part of the foreground
        % The threshold is scaled by the maximum distance to operate in the 0-1 range expected by graythresh
        processingMask = euclideanDistanceMap <= (segmentationThreshold * max(euclideanDistanceMap(:)));

        % --- Apply Morphological Operations and Refinements ---
        % These operations help to clean up the mask and produce a smoother result.

        % Fill holes in the mask (pixels inside the mask boundary but currently false)
        processingMask = imfill(processingMask, 'holes');

        % Keep only the largest connected component (assumed to be the main lesion)
        processingMask = bwareafilt(processingMask, 1);

        % Get dimensions for calculating structuring element size
        [imageRows, imageColumns] = size(processingMask);

        % Calculate a size for structuring elements based on image size
        structuringElementSize = round(min(imageRows, imageColumns) * 0.05); % 5% of the smaller dimension

        % Apply a closing operation with a disk-shaped structuring element
        % Closing helps to bridge small gaps and smooth the boundary
        closingStructuringElement = strel('disk', structuringElementSize, 0);
        processingMask = imclose(processingMask, closingStructuringElement);

        % Smooth the edges using Gaussian filtering (convert to double first)
        % Thresholding at 0.5 converts the smoothed image back to binary
        processingMask = imgaussfilt(double(processingMask), 2) > 0.5;

        % Apply further refinement with smaller disk-shaped structuring elements
        % This can help refine edges and remove small artifacts
        smoothingStructuringElement = strel('disk', round(structuringElementSize/1), 0); % Size adjusted
        processingMask = imopen(processingMask, smoothingStructuringElement); % Opening removes small objects and smooths boundaries
        processingMask = imclose(processingMask, smoothingStructuringElement); % Closing fills small holes and smooths boundaries

        % Store the final refined binary mask
        segmentationFinalMask = processingMask;

        % --- Display the Final Segmentation Mask ---

        % Display the resulting binary mask in the bottom-center axes
        imshow(segmentationFinalMask, 'Parent', axesSegmentationMask);
        title(axesSegmentationMask, 'Final Segmentation Mask'); % Add a title
    end

    % Function to display the original image masked by the final segmentation result.
    function showSegmentedLesion()
        % Check if the final segmentation mask is available
        if isempty(segmentationFinalMask)
            uialert(mainFigure, 'Please perform segmentation first.', 'Error', 'Icon', 'error');
            return; % Exit if segmentation hasn't been completed
        end

        % Apply the final mask to the original RGB image
        % bsxfun performs element-wise multiplication, effectively setting pixels
        % outside the mask (where mask is false/0) to zero in the RGB image.
        % cast ensures the mask is the same data type as the image for multiplication.
        resultSegmentedImage = bsxfun(@times, originalRGBImage, cast(segmentationFinalMask, 'like', originalRGBImage));

        % --- Display the Segmented Lesion ---

        % Display the masked original image in the bottom-right axes
        imshow(resultSegmentedImage, 'Parent', axesSegmentedResult);
        title(axesSegmentedResult, 'Segmented Lesion'); % Add a title
    end

end % End of the main function