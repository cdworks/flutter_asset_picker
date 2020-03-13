
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PickBaseCell extends StatefulWidget
{
  final Color selectedColor;
  final Color highlightColor;
  final Color normalColor;
  final bool  selected;
  final Widget child;
  final GestureTapCallback tapCallback;
  final GestureLongPressCallback longPressCallback;
  final ValueChanged<bool> onHighlightChanged;

  const PickBaseCell({@required this.child,
    this.tapCallback,
    this.longPressCallback,this.normalColor = Colors.white, this.onHighlightChanged,
    this.selectedColor = Colors.white,
    this.highlightColor = const Color(0xFFEAEAEA),this.selected = false}
      ): assert(child != null);

  @override
  State<StatefulWidget> createState() => _PickBaseCell();


}

class _PickBaseCell extends State<PickBaseCell>
{

  bool isHiLight = false;

//  Color getBgColor()
//  {
//    if(widget.selected) {
//      return widget.selectedColor;
//    }
//
//    return isHiLight ? widget.highlightColor:widget.normalColor;
//
//  }
//
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return GestureDetector(
      onTapDown: (TapDownDetails details)
      {
        if(!widget.selected)
        {
          setState(() {
            isHiLight = true;
            if(widget.onHighlightChanged != null)
            {
              widget.onHighlightChanged(true);
            }
          });
        }

      },
      onTapCancel: ()
      {

        if(!widget.selected) {
          if(widget.onHighlightChanged != null)
          {
            widget.onHighlightChanged(false);
          }
          setState(() {
            isHiLight = false;
          });
        }
        else
        {
          isHiLight = false;
        }
      },
      onTapUp: (TapUpDetails details)
      {

        if(!widget.selected) {
          if(widget.onHighlightChanged != null)
          {
            widget.onHighlightChanged(false);
          }

          Future.delayed(Duration(milliseconds: 50),(){
            setState(() {
              isHiLight = false;
            });
          });

        }
        else
        {
          isHiLight = false;
        }
      },
      onTap: widget.tapCallback,
      onLongPress: widget.longPressCallback,
      behavior: HitTestBehavior.opaque,
      child: Container(color: widget.selected ? widget.selectedColor : isHiLight ? widget.highlightColor : widget.normalColor, child: widget.child),
    );
  }
}