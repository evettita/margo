function clean_gui(axes_handle)

% clear any drawn objects on the axes
centroid_markers = findobj(axes_handle,'-depth',3,'Type','line');
delete(centroid_markers);
rect_handles = findobj(axes_handle,'-depth',3,'Type','rectangle');
delete(rect_handles);
text_handles = findobj(axes_handle,'-depth',3,'Type','text');
delete(text_handles);