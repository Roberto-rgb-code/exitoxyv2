import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomInfoWindowController {
  GoogleMapController? googleMapController;
  Function? onCameraMove;
  Function? addInfoWindow;
  Function? hideInfoWindow;

  void dispose() {
    googleMapController = null;
    onCameraMove = null;
    addInfoWindow = null;
    hideInfoWindow = null;
  }
}

class CustomInfoWindow extends StatefulWidget {
  final CustomInfoWindowController controller;
  final double height;
  final double width;
  final double offset;

  const CustomInfoWindow({
    Key? key,
    required this.controller,
    this.height = 180,
    this.width = 200,
    this.offset = 80,
  }) : super(key: key);

  @override
  State<CustomInfoWindow> createState() => _CustomInfoWindowState();
}

class _CustomInfoWindowState extends State<CustomInfoWindow> {
  bool _showInfoWindow = false;
  Widget? _infoWindow;
  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    widget.controller.addInfoWindow = _addInfoWindow;
    widget.controller.hideInfoWindow = _hideInfoWindow;
    widget.controller.onCameraMove = _onCameraMove;
  }

  void _addInfoWindow(Widget infoWindow, LatLng latLng) {
    setState(() {
      _infoWindow = infoWindow;
      _currentLatLng = latLng;
      _showInfoWindow = true;
    });
  }

  void _hideInfoWindow() {
    setState(() {
      _showInfoWindow = false;
      _infoWindow = null;
      _currentLatLng = null;
    });
  }

  void _onCameraMove() {
    if (_showInfoWindow && _currentLatLng != null) {
      widget.controller.googleMapController?.getLatLng(ScreenCoordinate(
        x: 0,
        y: 0,
      )).then((latLng) {
        // Actualizar posición si es necesario
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showInfoWindow || _infoWindow == null || _currentLatLng == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: MediaQuery.of(context).size.width / 2 - widget.width / 2,
      top: MediaQuery.of(context).size.height / 2 - widget.height / 2 - widget.offset,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _infoWindow!,
          ),
        ),
      ),
    );
  }
}
