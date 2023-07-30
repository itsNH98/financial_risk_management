function data = importFrenchData(zipname, outdir)
% Reference Oleg Komarov (2023). okomarov/importFrenchData (https://github.com/okomarov/importFrenchData), GitHub. Retrieved July 30, 2023.
% IMPORTFRENCHDATA Imports datasets from Kenneth French's Data Library webpage
%
%   IMPORTFRENCHDATA() 
%       Lists available datasets, their ZIPNAMEs and the description.
%
%   IMPORTFRENCHDATA(ZIPNAME) 
%       Imports into a table the dataset specified by 'ZIPNAME'.
%
%   IMPORTFRENCHDATA(...,OUTPATH) 
%       Specify name and folder where to save the imported data. By default
%       the dataset will be saved under the current directory as '.\ZIPNAME.mat'
%
% See <a href="http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/data_library.html">Fama French data</a>

url = 'http://mba.tuck.dartmouth.edu/pages/faculty/ken.french/';

% List available datasets on Kennet's page
if nargin < 1
    list = listAvailableData(url);
    data = list;
    return
end
if nargin < 2
    outdir = '';
end

% Try to load from web
try
    txtfile = unzip([url, 'ftp/', zipname], tempdir);
catch
    error('Problem with importing')
end

% Parse .txt dataset:
%   Usually has few lines of description followed by one blank line, one
%   line of variable names, and then data. Uses multiple whitespaces as
%   delimiter.
fid   = fopen(char(txtfile));
clean = onCleanup(@() cleanupFcn(fid,txtfile{:}));
tline = fgetl(fid);
Desc  = '';
while ischar(tline)
    if isempty(tline)
        tline = fgetl(fid);
        continue
    end
    
    % First line of data?
    tmp      = textscan(tline, '%d','MultipleDelimsAsOne',true);
    tmp      = tmp{1};
    ncoldata = numel(tmp);
    if ~isempty(tmp) && ncoldata > 1
        % Parse previous line for variable names
        vnames     = textscan(prevline, '%s','MultipleDelimsAsOne',true);
        vnames     = vnames{1};
        % Create variable names
        hasHeaders = ncoldata == numel(vnames)+1 && vnames{end}(end) ~= '.';
        if hasHeaders
            vnames = strrep(vnames,'-','Minus');
        else
            vnames = arrayfun(@(x) sprintf('%d',x), 1:ncoldata-1,'un',0);
        end
        % Sanitize names
        vnames = matlab.lang.makeValidName(vnames,'Prefix','Var');
        vnames = matlab.lang.makeUniqueStrings(vnames);
        
        % Add date
        vnames = ['Date'; vnames(:)];
        
        % Rewind to beginning of data
        fseek(fid, prevpos, 'bof');
        break
    else
        % Store description
        Desc = [Desc, tline];
    end
    
    prevpos  = ftell(fid);
    prevline = tline;
    tline    = fgetl(fid);
end

% Parse data
fmt = ['%u' repmat('%f',1, ncoldata-1)];
txt = textscan(fid, fmt,'MultipleDelimsAsOne',true);

% Convert into table
data                        = table(txt{:},'VariableNames', vnames);
data.Properties.Description = Desc;

% Save
[~,name] = fileparts(zipname);
save(fullfile(outdir,[name,'.mat']), 'data')
end

function list = listAvailableData(url)
% Import webpage
str = webread([url,'/data_library.html']);

% Remove comments
cStart = regexp(str,'<!','start');
cEnd   = regexp(str,'-->','end');
for ii = numel(cEnd):-1:1
    str(cStart(ii):cEnd(ii)) = [];
end

% Parse links
[Link,start] = regexp(str, '<a href ?= ?"([^"]*)">','tokens','start');
Link         = cat(1,Link{:});

% Get ..._TXT.zip 
idx     = ~cellfun('isempty',regexp(Link,'_TXT.zip','once'));
Zipname = strrep(Link(idx),'ftp/','');
start   = start(idx);
list    = table(Zipname);

% Extract description
for ii = 1:numel(start)
    p                      = start(ii);
    tmp                    = regexp(str(p-250:p),'<[ba]>(.*)</b>','tokens');
    list.Description(ii,1) = tmp{1};
end
end

function cleanupFcn(fid,fname)
% Cleanup performed at end or error
fclose(fid);
delete(fname);
end