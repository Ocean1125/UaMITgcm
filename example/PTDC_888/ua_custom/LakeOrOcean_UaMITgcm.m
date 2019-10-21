
function [OceanNodes,LakeNodes,GLgeo,GLnodes,GLele]=LakeOrOcean(CtrlVar,MUA,GF,GLgeo,GLnodes,GLele)
%
% [NodesOcean,NodesLakes]=LakeOrOcean(CtrlVar,GF,Boundary,connectivity,coordinates)
%
% Tries to determine which floating nodes are part of the ocean and which belong to subglacial lakes
%
%    uses GLgeometry to determine the longest grounding line and assumes that this grounding line
%    represents the ocean boundary. Then determines if nodal point at floating level are inside or
%    outside of this boundary.
%
% May not always work, and anyhow I am not sure if one can always objectivily decide what is an ocean
% and what a lake.
%
% Note: GLgeo calculated is slighly different from the usual way of doing this
%       because here the grounding line needs to be closed.
%
% Returns a logical indexing (this was changed from indexing vectors on 20 Dec, 2018)
%
%%
OceanNodes=[];
LakeNodes=[];


% if ~isfield(CtrlVar,'GLthreshold')
%     CtrlVar.GLthreshold=0.5;
% end

% I=find(GF.node<CtrlVar.GLthreshold);   % all floating nodes
% I=GF.node<CtrlVar.GLthreshold;   % all floating nodes

if nargin<4 || isempty(GLgeo) || isempty(GLnodes) || isempty(GLele)
    [GLgeo,GLnodes,GLele]=GLgeometry(MUA.connectivity,MUA.coordinates,GF,CtrlVar);
end

if ~isfield(GF,'NodesDownstreamOfGroundingLines')
    [GF,GLgeo,GLnodes,GLele]=IceSheetIceShelves(CtrlVar,MUA,GF,GLgeo,GLnodes,GLele);
end

I=find(GF.NodesDownstreamOfGroundingLines | GF.NodesCrossingGroundingLines);
%I=find(GF.node<0.5);

if ~isempty(I)
    
    
    GFtemp=GF; GFtemp.node(MUA.Boundary.Nodes)=0;  % I need to `close' the grounding line, so I set all boundary nodes to floating status
    GLgeoMod=GLgeometry(MUA.connectivity,MUA.coordinates,GFtemp,CtrlVar);
    [xGL1,yGL1] = ArrangeGroundingLinePos(CtrlVar,GLgeoMod,1);
    
    x=MUA.coordinates(:,1); y=MUA.coordinates(:,2);
    %  IN = inpolygon(x(I),y(I),xGL,yGL);  % for some reason this standard matlab routine is much slower than inpoly
    [IN,ON] = inpoly([x(I) y(I)],[xGL1 yGL1],[],1);
    
    % There is a bit of a question here what to do with nodes that are
    % directly on the grounding line. I've here decided to consider them part of
    % the ocean.
    Ind=~IN  | ON ; % ocean nodes are not within grounding line, but can be on it
    
    
    OceanNodes=I(Ind);
    LakeNodes=I(~Ind);
    
    II=false(MUA.Nnodes,1);
    II(OceanNodes)=true;
    OceanNodes=II;
    
    II=false(MUA.Nnodes,1);
    II(LakeNodes)=true;
    LakeNodes=II;
    
    if CtrlVar.doplots && CtrlVar.PlotOceanLakeNodes
        
        figure
        hold off
        
        
        plot(x(OceanNodes)/CtrlVar.PlotXYscale,y(OceanNodes)/CtrlVar.PlotXYscale,'og','DisplayName','Ocean Nodes') ; hold on
        plot(x(LakeNodes)/CtrlVar.PlotXYscale,y(LakeNodes)/CtrlVar.PlotXYscale,'or','DisplayName','Lace Nodes')
        legend
        
        PlotFEmesh(MUA.coordinates,MUA.connectivity,CtrlVar) ; hold on 
        plot(xGL1/CtrlVar.PlotXYscale,yGL1/CtrlVar.PlotXYscale,'k','LineWidth',2);
        [xGL,yGL,GLgeo]=PlotGroundingLines(CtrlVar,MUA,GF,GLgeo,[],[],'r');
        %plot(GLgeo(:,[3 4])'/CtrlVar.PlotXYscale,GLgeo(:,[5 6])'/CtrlVar.PlotXYscale,'r','LineWidth',1);
        %plot(x(Boundary.EdgeCornerNodes)/CtrlVar.PlotXYscale,y(Boundary.EdgeCornerNodes)/CtrlVar.PlotXYscale,'k.-')
        %plot(x(Boundary.Nodes)/CtrlVar.PlotXYscale,y(Boundary.Nodes)/CtrlVar.PlotXYscale,'ro')
        axis equal tight
        hold on
        title('Ocean/Lake nodes')
        
        
    end
end
end