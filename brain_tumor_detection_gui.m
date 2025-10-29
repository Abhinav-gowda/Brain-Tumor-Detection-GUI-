% Brain Tumor Detection GUI
% Author: Shady Nikooei
% Enhanced with interactive interface

function brain_tumor_gui
    % Create the main figure
    fig = uifigure('Name', 'Brain Tumor Detection System', ...
                   'Position', [100, 100, 1200, 700], ...
                   'Color', [0.95, 0.95, 0.95]);
    
    % Title Panel
    titlePanel = uipanel(fig, 'Position', [10, 640, 1180, 50], ...
                         'BackgroundColor', [0.2, 0.4, 0.8], ...
                         'BorderType', 'none');
    
    uilabel(titlePanel, 'Text', 'Brain Tumor Detection and Classification System', ...
            'Position', [20, 10, 800, 30], ...
            'FontSize', 18, ...
            'FontWeight', 'bold', ...
            'FontColor', 'white');
    
    % Upload Button
    uploadBtn = uibutton(titlePanel, 'push', ...
                        'Text', 'Upload MRI Image', ...
                        'Position', [900, 10, 250, 30], ...
                        'FontSize', 14, ...
                        'FontWeight', 'bold', ...
                        'BackgroundColor', [0.3, 0.7, 0.3], ...
                        'FontColor', 'white', ...
                        'ButtonPushedFcn', @(btn,event) uploadImage());
    
    % Image Display Panels
    % Original Image Panel
    panel1 = uipanel(fig, 'Position', [10, 350, 380, 280], ...
                     'Title', 'Original MRI Image', ...
                     'FontSize', 12, ...
                     'FontWeight', 'bold', ...
                     'BackgroundColor', 'white');
    ax1 = uiaxes(panel1, 'Position', [10, 10, 360, 240]);
    axis(ax1, 'off');
    
    % Segmented Tumor Mask Panel
    panel2 = uipanel(fig, 'Position', [400, 350, 380, 280], ...
                     'Title', 'Segmented Tumor Mask', ...
                     'FontSize', 12, ...
                     'FontWeight', 'bold', ...
                     'BackgroundColor', 'white');
    ax2 = uiaxes(panel2, 'Position', [10, 10, 360, 240]);
    axis(ax2, 'off');
    
    % Highlighted Tumor Panel
    panel3 = uipanel(fig, 'Position', [790, 350, 380, 280], ...
                     'Title', 'Highlighted Tumor', ...
                     'FontSize', 12, ...
                     'FontWeight', 'bold', ...
                     'BackgroundColor', 'white');
    ax3 = uiaxes(panel3, 'Position', [10, 10, 360, 240]);
    axis(ax3, 'off');
    
    % Radial Distance Graph Panel
    panel4 = uipanel(fig, 'Position', [10, 80, 760, 260], ...
                     'Title', 'Radial Distance Signature', ...
                     'FontSize', 12, ...
                     'FontWeight', 'bold', ...
                     'BackgroundColor', 'white');
    ax4 = uiaxes(panel4, 'Position', [20, 20, 720, 210]);
    
    % Classification Result Panel
    resultPanel = uipanel(fig, 'Position', [780, 80, 390, 260], ...
                          'Title', 'Classification Result', ...
                          'FontSize', 12, ...
                          'FontWeight', 'bold', ...
                          'BackgroundColor', 'white');
    
    resultLabel = uilabel(resultPanel, 'Text', 'Upload an MRI image to begin analysis', ...
                          'Position', [20, 150, 350, 80], ...
                          'FontSize', 16, ...
                          'FontWeight', 'bold', ...
                          'HorizontalAlignment', 'center', ...
                          'VerticalAlignment', 'center', ...
                          'WordWrap', 'on');
    
    varianceLabel = uilabel(resultPanel, 'Text', '', ...
                            'Position', [20, 80, 350, 40], ...
                            'FontSize', 13, ...
                            'HorizontalAlignment', 'center');
    
    statusLabel = uilabel(resultPanel, 'Text', '', ...
                          'Position', [20, 30, 350, 40], ...
                          'FontSize', 11, ...
                          'HorizontalAlignment', 'center', ...
                          'FontColor', [0.5, 0.5, 0.5]);
    
    % Status Bar at bottom
    statusBar = uilabel(fig, 'Text', 'Ready. Please upload an MRI image.', ...
                        'Position', [10, 10, 1180, 30], ...
                        'FontSize', 11, ...
                        'BackgroundColor', [0.9, 0.9, 0.9], ...
                        'HorizontalAlignment', 'center');
    
    % Upload Image Function
    function uploadImage()
        [filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp;*.tif', 'Image Files (*.jpg, *.png, *.bmp, *.tif)'}, ...
                                         'Select MRI Image');
        
        if isequal(filename, 0)
            statusBar.Text = 'No file selected.';
            return;
        end
        
        statusBar.Text = 'Processing image...';
        drawnow;
        
        try
            % Read the image
            image_path = fullfile(pathname, filename);
            original_img = imread(image_path);
            
            % Display original image
            imshow(original_img, 'Parent', ax1);
            axis(ax1, 'off');
            
            % Segment tumor
            [binary_mask, segmented_tumor_img] = segment_tumor(original_img);
            
            if isempty(binary_mask)
                resultLabel.Text = 'No tumor detected';
                resultLabel.FontColor = [0.8, 0.4, 0];
                varianceLabel.Text = '';
                statusLabel.Text = '';
                statusBar.Text = 'Analysis complete: No tumor detected.';
                cla(ax2); cla(ax3); cla(ax4);
                return;
            end
            
            % Display segmented mask
            imshow(binary_mask, 'Parent', ax2);
            axis(ax2, 'off');
            
            % Display highlighted tumor
            imshow(segmented_tumor_img, 'Parent', ax3);
            axis(ax3, 'off');
            
            % Feature extraction
            boundaries = bwboundaries(binary_mask);
            props = regionprops(binary_mask, 'Centroid', 'Area');
            [~, idx] = max([props.Area]);
            tumor_boundary = boundaries{idx};
            center = props(idx).Centroid;
            
            x_boundary = tumor_boundary(:, 2);
            y_boundary = tumor_boundary(:, 1);
            radial_distances = sqrt((x_boundary - center(1)).^2 + (y_boundary - center(2)).^2);
            
            margin_variance = var(radial_distances);
            
            % Classification
            variance_threshold = 50;
            
            if margin_variance < variance_threshold
                classification = 'BENIGN';
                resultLabel.FontColor = [0.2, 0.7, 0.2];
            else
                classification = 'MALIGNANT';
                resultLabel.FontColor = [0.9, 0.2, 0.2];
            end
            
            % Update result display
            resultLabel.Text = ['Tumor Classification: ', classification];
            varianceLabel.Text = sprintf('Variance: %.2f', margin_variance);
            statusLabel.Text = sprintf('Threshold: %.2f', variance_threshold);
            
            % Plot radial distance
            plot(ax4, radial_distances, 'LineWidth', 2, 'Color', [0.2, 0.4, 0.8]);
            title(ax4, sprintf('Radial Distance Variance: %.2f', margin_variance), ...
                  'FontSize', 11, 'FontWeight', 'bold');
            xlabel(ax4, 'Boundary Points', 'FontSize', 10);
            ylabel(ax4, 'Distance from Center (pixels)', 'FontSize', 10);
            grid(ax4, 'on');
            
            max_dist = max(radial_distances);
            padding = max_dist * 0.1;
            ylim(ax4, [0, max_dist + padding]);
            
            statusBar.Text = sprintf('Analysis complete: Tumor classified as %s', classification);
            
        catch ME
            errordlg(['Error processing image: ', ME.message], 'Error');
            statusBar.Text = 'Error occurred during processing.';
        end
    end
end

% Tumor Segmentation Function (Your original logic)
function [tumor_mask, highlighted_image] = segment_tumor(original_img)
    g_img = im2gray(original_img);
    thresh = graythresh(g_img);
    brain_mask = imbinarize(g_img, thresh);
    brain_mask = imfill(brain_mask, 'holes');
    brain_mask = bwareaopen(brain_mask, 500);
    
    brain_only_img = g_img;
    brain_only_img(~brain_mask) = 0;
    
    if ~any(brain_only_img(:))
        tumor_mask = [];
        highlighted_image = [];
        return;
    end
    
    brain_intensity_values = g_img(brain_mask);
    tumor_threshold_normalized = graythresh(brain_intensity_values);
    tumor_mask = imbinarize(brain_only_img, tumor_threshold_normalized);
    tumor_mask = bwareaopen(tumor_mask, 200);
    
    se = strel('disk', 5);
    tumor_mask = imclose(tumor_mask, se);
    
    red_channel = g_img;
    green_channel = g_img;
    blue_channel = g_img;
    red_channel(tumor_mask) = 255;
    green_channel(tumor_mask) = 0;
    blue_channel(tumor_mask) = 0;
    highlighted_image = cat(3, red_channel, green_channel, blue_channel);
end
