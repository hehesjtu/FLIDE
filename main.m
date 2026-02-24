function UI
    % =====================================================================
    % Title: FLIDE Image Enhancement Demo Platform 
    % =====================================================================

    % --- Global Variables ---
    hFig = [];
    img_origin = [];         % Original Image I0 
    img_FLIDE_Enhanced = []; % FLIDE Result 
    SCALE_FACTOR = 1.25; 
  
    createInterface();

    function createInterface()
        hFig = figure('Name', 'FLIDE Image Enhancement System', ...
                      'NumberTitle', 'off', ...
                      'MenuBar', 'none', ...
                      'ToolBar', 'none', ...
                      'Position', [100, 100, 1100, 600], ... 
                      'Color', [0.94 0.94 0.94]);

        hPanel = uipanel('Parent', hFig, 'Position', [0, 0.88, 1, 0.12], ...
                         'BackgroundColor', [0.94 0.94 0.94], 'BorderType', 'none');

       
        uicontrol('Parent', hPanel, 'Style', 'pushbutton', 'String', 'Load Image', ...
                  'FontSize', 11, 'FontWeight', 'bold', ...
                  'Position', [20, 20, 120, 40], ...
                  'Callback', @cb_LoadImage, 'BackgroundColor', [1 1 1]);

        
        uicontrol('Parent', hPanel, 'Style', 'pushbutton', 'String', 'Launch FLIDE', ...
                            'FontSize', 11, 'FontWeight', 'bold', ...
                            'Position', [160, 20, 120, 40], ...
                            'Callback', @cb_RunFLIDE, 'Enable', 'off', 'Tag', 'BtnRun', ...
                            'BackgroundColor', [0.2 0.6 1], 'ForegroundColor', [1 1 1]);
        
        
        uicontrol('Parent', hPanel, 'Style', 'text', 'String', 'Enhancement Factor:', ...
                  'FontSize', 11, 'Position', [300, 30, 150, 20], ... 
                  'BackgroundColor', [0.94 0.94 0.94], 'HorizontalAlignment', 'right');
        
        uicontrol('Parent', hPanel, 'Style', 'edit', 'String', '4.0', ...
                  'FontSize', 11, 'Position', [460, 28, 60, 28], ...
                  'Tag', 'EditFactor', 'BackgroundColor', [1 1 1]);

      
        uicontrol('Parent', hPanel, 'Style', 'text', 'String', 'Ready - Please load an image.', ...
                  'FontSize', 10, 'Position', [540, 28, 500, 25], ...
                  'BackgroundColor', [0.94 0.94 0.94], 'HorizontalAlignment', 'left', ...
                  'Tag', 'StatusText', 'ForegroundColor', [0.4 0.4 0.4]);

        % === Image Display Area ===
        
        % Left: Original Image
        hAx1 = axes('Parent', hFig, 'Position', [0.02, 0.15, 0.47, 0.68]);
        title(hAx1, 'Input Image', 'FontSize', 12, 'FontWeight', 'bold');
        axis(hAx1, 'off'); set(hAx1, 'Tag', 'AxOrigin');

        % Right: Result Image
        hAx2 = axes('Parent', hFig, 'Position', [0.51, 0.15, 0.47, 0.68]);
        title(hAx2, 'FLIDE Enhanced Result', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0 0.4 0.8]);
        axis(hAx2, 'off'); set(hAx2, 'Tag', 'AxFLIDE');

        
        % Save Button 
        uicontrol('Parent', hFig, 'Style', 'pushbutton', 'String', 'Save Result', ...
                  'FontSize', 10, 'Position', [900, 20, 120, 35], ...
                  'Callback', @cb_SaveFLIDE, 'Enable', 'off', 'Tag', 'BtnSaveFLIDE');

        % PSNR / SSIM Display Label
        uicontrol('Parent', hFig, 'Style', 'text', 'String', '', ...
                  'FontSize', 12, 'FontWeight', 'bold', ...
                  'Position', [500, 25, 380, 30], ...
                  'BackgroundColor', [0.94 0.94 0.94], 'HorizontalAlignment', 'center', ...
                  'Tag', 'TextMetrics', 'ForegroundColor', [0.8 0 0]);
    end

    % --- Callback: Load Image ---
    function cb_LoadImage(~, ~)
        [filename, pathname] = uigetfile({'*.png;*.jpg;*.bmp;*.tif', 'Images'}, 'Select Image');
        if isequal(filename, 0), return; end
        
        filepath = fullfile(pathname, filename);
        setStatus('Loading image...');
        
        try
            raw_img = imread(filepath);
            img_origin = double(raw_img); 
            
           
            hAx = findobj(hFig, 'Tag', 'AxOrigin');
            imshow(uint8(img_origin), 'Parent', hAx);
            title(hAx, sprintf('Input Image (%dx%d)', size(img_origin, 2), size(img_origin, 1)));
            
            cla(findobj(hFig, 'Tag', 'AxFLIDE'));
            img_FLIDE_Enhanced = [];
            set(findobj(hFig, 'Tag', 'TextMetrics'), 'String', '');
            set(findobj(hFig, 'Tag', 'BtnRun'), 'Enable', 'on');
            set(findobj(hFig, 'Tag', 'BtnSaveFLIDE'), 'Enable', 'off');
            setStatus(['Loaded: ' filename]);
        catch ME
            errordlg(ME.message);
        end
    end

    % --- Callback: Execute FLIDE ---
    function cb_RunFLIDE(~, ~)
        if isempty(img_origin), return; end
        
        % Get Parameters
        factor_str = get(findobj(hFig, 'Tag', 'EditFactor'), 'String');
        enhance_factor = str2double(factor_str);
        if isnan(enhance_factor), enhance_factor = 4.0; end

        % Check for FLIDE file
        if exist('FLIDE', 'file') == 0
            errordlg('FLIDE executable (m/p file) not found in current directory!', 'File Missing Error'); return;
        end
        
        setStatus('Processing FLIDE, please wait...'); drawnow;
        
        try
            tic;
            [rows, cols, channels] = size(img_origin);
            Details_FLIDE = zeros(rows, cols, 3);
            
            % Unified channel processing logic
            if channels == 1
                img_process = cat(3, img_origin, img_origin, img_origin);
                proc_channels = 3;
            else
                img_process = img_origin;
                proc_channels = channels;
            end

            % --- Channel-wise Processing ---
            for c = 1 : proc_channels
                I0_slice = img_process(:, :, c);
                L1_slice = imresize(I0_slice, SCALE_FACTOR, 'bilinear');
                L0_blurred = imresize(L1_slice, size(I0_slice), 'bilinear');
                H0_slice = double(I0_slice) - double(L0_blurred);
                Res_Large = FLIDE(I0_slice, L1_slice, H0_slice);
                Details_FLIDE(:, :, c) = imresize(Res_Large, [rows, cols], 'bilinear');
                
                % Progress prompt
                if proc_channels > 1
                    fprintf('Processing Channel %d/%d...\n', c, proc_channels);
                end
            end
            
            % --- Synthesize Final Result ---
            Out_FLIDE = zeros(size(img_process));
            for c = 1 : proc_channels
                Out_FLIDE(:, :, c) = img_process(:, :, c) + Details_FLIDE(:, :, c) * enhance_factor;
            end
         
            Out_FLIDE = uint8(max(0, min(255, Out_FLIDE)));
            
            if channels == 1
                Out_FLIDE = Out_FLIDE(:, :, 1);
            end

            img_FLIDE_Enhanced = Out_FLIDE;
            ref_img_uint8 = uint8(img_origin);
            
            % Calculate Metrics
            val_psnr = psnr(Out_FLIDE, ref_img_uint8);
            val_ssim = ssim(Out_FLIDE, ref_img_uint8);
            
            metrics_str = sprintf('PSNR: %.2f dB  |  SSIM: %.4f', val_psnr, val_ssim);
            set(findobj(hFig, 'Tag', 'TextMetrics'), 'String', metrics_str);

            % --- Refresh Display ---
            hAxFLIDE = findobj(hFig, 'Tag', 'AxFLIDE');
            imshow(img_FLIDE_Enhanced, 'Parent', hAxFLIDE);
            title(hAxFLIDE, sprintf('FLIDE Enhanced Result (Factor=%.1f)', enhance_factor));
            
            set(findobj(hFig, 'Tag', 'BtnSaveFLIDE'), 'Enable', 'on');
            setStatus(sprintf('Done! Time: %.2f s', toc));
            
        catch ME
            setStatus('Execution Error');
            errordlg(ME.message);
        end
    end

    % --- Callback: Save Result ---
    function cb_SaveFLIDE(~, ~)
        if isempty(img_FLIDE_Enhanced), return; end
        
        default_name = sprintf('FLIDE_Result_%s.png', datestr(now, 'HHMMSS'));
        [f, p] = uiputfile('*.png', 'Save Result', default_name);
        
        if f
            imwrite(img_FLIDE_Enhanced, fullfile(p, f));
            setStatus(['Saved: ' f]);
        end
    end

    % --- Helper: Update Status ---
    function setStatus(str)
        set(findobj(hFig, 'Tag', 'StatusText'), 'String', str);
    end
end