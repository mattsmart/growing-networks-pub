function [evolutionary_graph, relabeled_image, adjacency_mat] = plot_network_cube_simplified_linear_updated(chosen_region_label, append_linear)
% Basic explanation:
% This code takes the matrix from the sweep and converts it into an
% adjacency matrix (see evolutionary_graph).
% Each distinct region of the matrix corresponding to the same final
% network gets a unique name and ID (see relabeled_image).
% Then, two regions which produce different graphs are connected if they
% contact each other in parameter space.

% inputs:
% 1. append_linear
% if append_linear == true, then combine 6-cell linear to 16-cell linear into one label.

% see cell_array_names below -- also, see preset_bionetworks.py for isos

% outputs: 
% evolutionary_graph: adjacency matrix representation of the the iso matrix from the sweep
% nodes correspond to regions generating a known graph (potentially more than one per graph)
% edges represent adjacency of two different regions in parameter space (i.e., in the iso matrix)

% relabeled_image: a matrix which relabels regions according to unique
% region IDs (thus, accounting for the possibility more than one region per graph)
% the corresponding region IDs are also stored in the graph

% turn off matlab warning generated when adding nodes
warning('off','MATLAB:table:RowsAddedExistingVars')

% indices of networks not produced in main sweep of paper (see below)
% 4 - (not produced in sweep)
% 5 - (not produced in sweep)
% 13 - (not produced in sweep)
% 28 - (not produced in sweep)
% 29 - (not produced in sweep)
cell_array_names = {'one cell', 'N. vitripennis', 'D. melanogaster', 'L. humile', 'B. terrestris', 'G. natator', 'C. perla main', 'C. perla secondary', ...
    'C. perla tertiary', 'O. labronica', 'P. sauteri', 'P. communis', 'D. parthenogeneticus', ...
    '5-cell linear', '6-cell linear', '7-cell linear', '8-cell linear', '9-cell linear', ...
    '10-cell linear', '11-cell linear', '12-cell linear', '13-cell linear', ...
    '14-cell linear', '15-cell linear', '16-cell linear', 'H. juglandis', 'fulvicephalus1', ...
    'fulvicephalus2', 'fulvicephalus3'};
% N.B.: 15 -> 25 is 6-cell-linear -> 16-cell-linear
% if append_linear == true, then combine 6-cell linear to 16-cell linear into one label.
color_array_for_above_names = zeros(size(cell_array_names, 2), 3);
color_array_for_above_names(1,:) = [1,0,0];
color_array_for_above_names(2,:) = [0,1,0];
color_array_for_above_names(3,:) = [0,0,0];
color_array_for_above_names(6,:) = [1,0,1];
color_array_for_above_names(7,:) = [1,1,0]; % y
color_array_for_above_names(8,:) = [0,1,1]; % c
color_array_for_above_names(9,:) = [0,0,1]; % b
color_array_for_above_names(10,:) = [0.929,0.694,0.125]; % 
color_array_for_above_names(11,:) = [0.6350,0.0780,0.184]; %
color_array_for_above_names(12,:) = [0.85,0.325,0.0980]; %
color_array_for_above_names(14,:) = [0.301,0.745,0.933]; %
color_array_for_above_names(15,:) = [0.4940, 0.1840, 0.556]; %
color_array_for_above_names(16,:) = [0.4940, 0.1840, 0.556]; %
color_array_for_above_names(17,:) = [0.4940, 0.1840, 0.556]; %
color_array_for_above_names(18,:) = [0.4940, 0.1840, 0.556]; %
color_array_for_above_names(19,:) = [0.4940, 0.1840, 0.556]; %
color_array_for_above_names(20,:) = [0.4940, 0.1840, 0.556]; %
color_array_for_above_names(21,:) = [0.4940, 0.1840, 0.556]; %
color_array_for_above_names(22,:) = [0.4940, 0.1840, 0.556]; %
color_array_for_above_names(23,:) = [0.4940, 0.1840, 0.556]; %
color_array_for_above_names(24,:) = [0.4940, 0.1840, 0.556]; %
color_array_for_above_names(25,:) = [0.4940, 0.1840, 0.556]; %
color_array_for_above_names(26,:) = [255, 192, 203] / 255; %
color_array_for_above_names(27,:) = [211, 211, 211] / 255; % 


%% read these in without taking as input -- make sure data are stored in appropriately name folder.

% check that appropriate folder exists
folder_with_big_sweep = '../input/archive_sweeps/3D/big_100x160x181_beta0_zpulse_divPlusMinus/';
assert(exist(folder_with_big_sweep) == 7);

unique_ID_filename = [folder_with_big_sweep, 'unique_net_id.npy'];
assert(exist(unique_ID_filename) == 2);

num_cell_filename = [folder_with_big_sweep, 'num_cells.npy'];
assert(exist(num_cell_filename) == 2);

file_name_isos = [folder_with_big_sweep, 'isos.npy'];
assert(exist(num_cell_filename) == 2);

npy_state_tensor_unique_ID = readNPY(unique_ID_filename);
npy_state_tensor_num_cells = readNPY(num_cell_filename);
npy_state_tensor_isos = readNPY(file_name_isos);

assert(isequal(size(npy_state_tensor_unique_ID), size(npy_state_tensor_num_cells)));

% assert size of npy_state_tensor_isos be the size of sweep used to produce Fig. 4
% size(npy_state_tensor_isos) == [100   160   181]
assert(isequal(size(npy_state_tensor_isos), [100   160   181]));

% if append_linear == true, then combine 6-cell linear to 16-cell linear into one label.
if (append_linear)
    find_vals_linear = find(npy_state_tensor_isos(:) >= 15 & npy_state_tensor_isos(:) <= 25);
    npy_state_tensor_isos(find_vals_linear) = 15;
    for i = 15:25
        cell_array_names{1,i} = '6-to-16-cell linear';
    end
end

% define relabeled image -- this allows us to identify distinct regions of parameter space which produce the same cyst.
relabeled_image = zeros(size(npy_state_tensor_isos));
% region counter
region_counter = 1;
% empty graph
evolutionary_graph = graph;

% pulse_vel, diffusion_arg, alpha
% See manuscript for sweep grid (stored in X, Y, Z)
% size(npy_state_tensor_isos) == [100   160   181]
% Here the XYZ grid is converted to real parameter values in a hard-coded manner.
% NOTE: divide v by 8 -- check this.
[X, Y, Z] = meshgrid(1:size(npy_state_tensor_isos, 2), 1:size(npy_state_tensor_isos, 1), 1:size(npy_state_tensor_isos, 3));
Xorig = X;
Yorig = Y;
Zorig = Z;
X = X - 1;
X = X * 8.0/159;
Y = Y - 1;
Y = Y * (0.14-0.045)/99;
Y = Y + 0.045;
Y = Y / 8; % normalize v
Z = Z - 1;
Z = Z * 0.001;
Z = Z - 0.09;

% can cut out regions which lie at large absolute values of the division
% asymmetry (... only if wanting to restrict range in delta).
% If you want to only visualize the results for less asymmetric divisions.
cutoff_in_mag = 0.1;

label_number = 1;
stats = regionprops3(npy_state_tensor_isos==label_number,"Centroid","Volume","VoxelIdxList");
assert(length(find(stats.Volume>1)) == 1); % one cell region is one large contiguous region
evolutionary_graph = addnode(evolutionary_graph, cell_array_names{1,label_number});
evolutionary_graph.Nodes.Volume = stats.Volume;
voxID = stats.VoxelIdxList{1,1};
Zvals = Z(voxID);
for i = 1:length(voxID)
    relabeled_image(voxID(i)) = region_counter;
end
evolutionary_graph.Nodes.RegionLabel = region_counter;
evolutionary_graph.Nodes.magabovecutoff = all(abs(Zvals)>=cutoff_in_mag);
region_counter = region_counter + 1;
mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
evolutionary_graph.Nodes.Centroid = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
evolutionary_graph.Nodes.Color = color_array_for_above_names(label_number,:);

for label_number = 2:size(cell_array_names,2)

    currentnumNodes = numnodes(evolutionary_graph);
    stats = regionprops3(npy_state_tensor_isos==label_number,"Centroid","Volume","VoxelIdxList");

    if (length(find(stats.Volume>1)) == 1)

        evolutionary_graph = addnode(evolutionary_graph, cell_array_names{1,label_number});
        evolutionary_graph.Nodes.Volume(currentnumNodes + 1) = stats.Volume;
        voxID = stats.VoxelIdxList{1,1};
        Zvals = Z(voxID);
        for i = 1:length(voxID)
            relabeled_image(voxID(i)) = region_counter;
        end

        evolutionary_graph.Nodes.RegionLabel(currentnumNodes + 1) = region_counter;
        region_counter = region_counter + 1;

        evolutionary_graph.Nodes.Color(currentnumNodes + 1,:) = color_array_for_above_names(label_number,:);
        mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
        evolutionary_graph.Nodes.Centroid(currentnumNodes + 1,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
        evolutionary_graph.Nodes.magabovecutoff(currentnumNodes + 1) = all(abs(Zvals)>=cutoff_in_mag);

        
    elseif (length(find(stats.Volume>1)) > 1)

        for i = 1:length(find(stats.Volume>1))
            evolutionary_graph = addnode(evolutionary_graph, [cell_array_names{1,label_number},' ',num2str(i)]);
        end

        counter = 1;
        for i = 1:length(stats.Volume)

            if (stats.Volume(i)>1)
                evolutionary_graph.Nodes.Volume(currentnumNodes+counter) = stats.Volume(i);

                voxID = stats.VoxelIdxList{i,1};
                Zvals = Z(voxID);
                assert(length(voxID) == stats.Volume(i));
                for j = 1:length(voxID)
                    relabeled_image(voxID(j)) = region_counter;
                end

                evolutionary_graph.Nodes.Color(currentnumNodes+counter,:) = color_array_for_above_names(label_number,:);

                evolutionary_graph.Nodes.RegionLabel(currentnumNodes+counter) = region_counter;
                evolutionary_graph.Nodes.magabovecutoff(currentnumNodes+counter) = all(abs(Zvals)>=cutoff_in_mag);
                mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                % NOTE: this code ensures that the points shown in Fig. 4 of main text fall
                % within a region producing the corresponding network.
                % code to ensure that the calculated representative point
                % falls within the region -- these are hard coded
                % the counters tell you which distinct region of that ISO was used in the figure
                if (counter == 4 && label_number == 6)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 6);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif ((counter == 4 || counter == 6 || counter == 7) && label_number == 7)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 7);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif ((counter == 1) && label_number == 8)
                    mean_val_pos = round([mean(Xorig(voxID(1))), mean(Yorig(voxID(1))), mean(Zorig(voxID(1)))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 8);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 1 && label_number == 9)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 9);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif  (counter == 2&& label_number == 10)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 10);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 8 && label_number == 11)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 11);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 1&& label_number == 12)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 12);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 2&& label_number == 14)
                    mean_val_pos = [12, 20, 74];
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 14);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 15 && label_number == 15)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 15);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 17 && label_number == 16)
                    mean_val_pos = round([mean(Xorig(voxID(1))), mean(Yorig(voxID(1))), mean(Zorig(voxID(1)))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 16);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 2 && label_number == 17)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 17);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 5 && label_number == 18)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 18);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 2 && label_number == 19)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 19);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 1 && label_number == 20)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 20);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 1 && label_number == 21)
                    mean_val_pos = round([mean(Xorig(voxID(1))), mean(Yorig(voxID(1))), mean(Zorig(voxID(1)))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 21);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 7 && label_number == 22)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 22);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 9 && label_number == 23)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 23);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 4 && label_number == 24)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 24);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 8 && label_number == 25)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 25);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];
                elseif (counter == 2 && label_number == 27)
                    mean_val_pos = round([mean(Xorig(voxID)), mean(Yorig(voxID)), mean(Zorig(voxID))]);
                    assert(npy_state_tensor_isos(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)) == 27);
                    evolutionary_graph.Nodes.Centroid(currentnumNodes+counter,:) = [X(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Y(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3)), Z(mean_val_pos(2), mean_val_pos(1), mean_val_pos(3))];

                end

                counter = counter + 1;
                region_counter = region_counter + 1;

            end

        end



    end

end

assert(region_counter-1 == numnodes(evolutionary_graph));

%%

adjacency_mat = zeros(numnodes(evolutionary_graph));

for i = 1:numnodes(evolutionary_graph)

    this_region_counter = evolutionary_graph.Nodes.RegionLabel(i);
    assert(i == this_region_counter);
    B_edited_image = zeros(size(relabeled_image));
    stats1 = regionprops3(relabeled_image==this_region_counter,"VoxelIdxList");
    voxID1 = stats1.VoxelIdxList{1,1};
    [I1,I2,I3] = ind2sub(size(relabeled_image),voxID1);

    for j = 1:length(voxID1)
        ind1 = I1(j);
        ind2 = I2(j);
        ind3 = I3(j);

        for ind1check = (ind1-1):(ind1+1)
            for ind2check = (ind2-1):(ind2+1)
                for ind3check = (ind3-1):(ind3+1)
                    if (ind1check > 0 && ind1check <= size(relabeled_image,1) && ind2check > 0 && ind2check <= size(relabeled_image,2) && ind3check > 0 && ind3check <= size(relabeled_image,3))
                        B_edited_image(ind1check, ind2check, ind3check) = 1;
                    end
                end
            end
        end

    end

    unique_neighbors = unique(relabeled_image(find(B_edited_image(:) == 1)));
    unique_neighbors(find(unique_neighbors == 0)) = [];

    for j = 1:length(unique_neighbors)

        this_neighbor = unique_neighbors(j);

        edge_weight_calc = length(find(B_edited_image(:) == 1 & relabeled_image(:) == this_neighbor));

        if (i ~= this_neighbor)
            adjacency_mat(i,this_neighbor) = edge_weight_calc;
        end

    end
    disp(i);

end

for i = 1:numnodes(evolutionary_graph)

    assert(evolutionary_graph.Nodes.RegionLabel(i) == i);

end


for i = 1:numnodes(evolutionary_graph)
    for j = i+1:numnodes(evolutionary_graph)

        if (adjacency_mat(i,j) > 0)
            evolutionary_graph = addedge(evolutionary_graph, i, j, (adjacency_mat(i,j) + adjacency_mat(j,i))/2);
        end

    end
end

%% sanity check: two distinct regions producing the same network can't be connected

for i = 1:numedges(evolutionary_graph)

    node1 = evolutionary_graph.Edges.EndNodes{i,1};
    node2 = evolutionary_graph.Edges.EndNodes{i,2};

    if (isequal(node1(1:3), node2(1:3)) && isequal(node1(end-2:end), node2(end-2:end)))

        disp(i);
        
        error('two have same first three');

    end

end

% turn back on matlab warning generated when adding nodes
warning('on','MATLAB:table:RowsAddedExistingVars')

%% write out csv file containing node info for fig. 4

NodeName = [];
for i = 1:numnodes(evolutionary_graph)
    NodeName = vertcat(NodeName, string(evolutionary_graph.Nodes.Name{i, 1}));
end

Centroid_Array = [];
for i = 1:numnodes(evolutionary_graph)
    Centroid_Array = vertcat(Centroid_Array, evolutionary_graph.Nodes.Centroid(i,:));
end

% store volume of param space for each node
Size_Data1 = [];
for i = 1:numnodes(evolutionary_graph)
    Size_Data1 = vertcat(Size_Data1, evolutionary_graph.Nodes.Volume(i));
end

total_volume_vect = zeros(size(cell_array_names,2),1);
for j = 1:size(cell_array_names,2)
    this_cell_array_name = cell_array_names{1,j};
    for i = 1:numnodes(evolutionary_graph)
        nodenameval = evolutionary_graph.Nodes.Name{i, 1};

        if (length(nodenameval)>=length(this_cell_array_name))

            if (isequal(nodenameval(1:length(this_cell_array_name)),this_cell_array_name))
                total_volume_vect(j) = total_volume_vect(j) + evolutionary_graph.Nodes.Volume(i);
            end

        end

    end
end

% sum of volumes for all nodes corresponding to a given isomorphism (e.g.,
% store the sum over all Drosophila node volumes).
Size_Data2 = zeros(size(Size_Data1));
for i = 1:numnodes(evolutionary_graph)
    this_region_counter = evolutionary_graph.Nodes.RegionLabel(i);

    associated_unique_ID = unique(npy_state_tensor_isos(find(relabeled_image(:) == this_region_counter)));
    assert(length(associated_unique_ID) == 1);

    Size_Data2(i) = length(find(npy_state_tensor_isos(:) == associated_unique_ID));
end

unique_ID_vect = zeros(size(Size_Data1));
for i = 1:numnodes(evolutionary_graph)
    this_region_counter = evolutionary_graph.Nodes.RegionLabel(i);

    associated_unique_ID = unique(npy_state_tensor_unique_ID(find(relabeled_image(:) == this_region_counter)));
    assert(length(associated_unique_ID) == 1);

    unique_ID_vect(i) = associated_unique_ID;
end

num_cells_vect = zeros(size(Size_Data1));
for i = 1:numnodes(evolutionary_graph)
    this_region_counter = evolutionary_graph.Nodes.RegionLabel(i);

    associated_num_cells = unique(npy_state_tensor_num_cells(find(relabeled_image(:) == this_region_counter)));
    assert(length(associated_num_cells) == 1);

    num_cells_vect(i) = associated_num_cells;
end

% non-natural reported structures
how_many_to_report = 3;
[top_contacting, ~, number_of_cells_top_contacting, volume_for_top_contacting, ...
    centroid_for_top_contacting] = find_non_reported_neighboring_networks(relabeled_image,...
    chosen_region_label, how_many_to_report, X, Y, Z, Xorig, Yorig, Zorig);

for i = 1:how_many_to_report
    NodeName = vertcat(NodeName, strcat(string(top_contacting(i)),"_",string(number_of_cells_top_contacting(i)) ) );
end

for i = 1:how_many_to_report
    Centroid_Array = vertcat(Centroid_Array, centroid_for_top_contacting(i,:));
end

% store volume of param space for each node
for i = 1:how_many_to_report
    Size_Data1 = vertcat(Size_Data1, volume_for_top_contacting(i));
end

for i = 1:how_many_to_report

    this_region_counter = top_contacting(i);

    Size_Data2 = vertcat(Size_Data2, length(find(npy_state_tensor_unique_ID(:) == this_region_counter)));

end

for i = 1:how_many_to_report

    this_region_counter = top_contacting(i);

    unique_ID_vect = vertcat(unique_ID_vect,this_region_counter);

end

for i = 1:how_many_to_report

    num_cells_vect = vertcat(num_cells_vect, number_of_cells_top_contacting(i));

end


tableVal = table(NodeName,Centroid_Array,Size_Data1,Size_Data2,unique_ID_vect,num_cells_vect);

writetable(tableVal,'Iso_Graph_Node_Info.csv');


end