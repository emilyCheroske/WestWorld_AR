//
//  ViewController.swift
//  WestWorldAR
//
//  Created by Emily Cheroske on 5/17/21.
//

import UIKit
import ArcGIS
import ArcGISToolkit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var arView: ArcGISARView!

    private var graphicsOverlay = AGSGraphicsOverlay()

    override func viewDidLoad() {

        super.viewDidLoad()

        setupARTableTopView()

    }

    private func setupARTableTopView() {

        // Create a scene with an imagery basemap
        //
        arView.sceneView.scene = AGSScene(basemap: AGSBasemap.imagery())

        // Add the surface to the scene
        //
        if let surface = getSurface() {
            arView.sceneView.scene?.baseSurface = surface
        }

        arView.sceneView.touchDelegate = self

        // Now, we need to setup the camera for our scene, here are a couple of filming locations (roughly) for WestWorld
        //
        //        - Canyonlands National Park: 38.12286952932182, -109.8509589363865
        //        - Murphy Point: 38.34310052611888, -109.89045917943194
        //        - Monument Valley: 36.99728633468969, -110.09849053314137
        //
        // For this demo, I'll be using the location for Murphy Point since I think it really captures the WestWorld vibe.
        //

        // Create and set the origin camera.
        //
        let camera = AGSCamera(latitude: 38.34310052611888, longitude: -109.89045917943194, altitude: 2500.852173, heading: 0, pitch: 90.0, roll: 0)
        arView.originCamera = camera

        // Set translationFactor. Think 'scale'
        //
        arView.translationFactor = 2000

        // This is the area around the center to show
        //
        arView.clippingDistance = 2000

        // Lets make the scene view a little opaque until the user taps on a surface
        //
        arView.sceneView.alpha = 0.1

        // Add the graphics layer to the view
        //
        arView.sceneView.graphicsOverlays.add(graphicsOverlay)

        arView.startTracking(.ignore)
    }
    
    // We need to add an elevation source to our scene view otherwise
    // the terrain will appear totally flat
    //
    private func getSurface() -> AGSSurface? {

        guard let url = URL(string: "https://elevation3d.arcgis.com/arcgis/rest/services/WorldElevation3D/Terrain3D/ImageServer") else {
            return nil
        }
        
        let elevationSource = AGSArcGISTiledElevationSource(url: url)
        let surface = AGSSurface()
        surface.elevationSources = [elevationSource]

        return surface
    }

}

extension ViewController: AGSGeoViewTouchDelegate {

    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {

        if arView.setInitialTransformation(using: screenPoint) {
            arView.sceneView.alpha = 1
        }
    }
}

extension ViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        // Place content only for anchors found by plane detection. We only care about horizontal planes.
        //
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .horizontal else { return }

        // Create a custom object to visualize the plane geometry and extent.
        //
        let plane = SCNNode()
        plane.geometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        plane.geometry?.materials.first?.diffuse.contents = UIColor.white.withAlphaComponent(0.5)
        plane.eulerAngles.x = -.pi / 2

        // Add the visualization to the ARKit-managed node so that it tracks
        // changes in the plane anchor as plane estimation continues.
        //
        node.addChildNode(plane)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

        // If the user selected a plane surface, we want to make sure that surface is being updated as
        // the device learns more about the environment
        //
        guard let planeAnchor = anchor as? ARPlaneAnchor,
              planeAnchor.alignment == .horizontal,
              let nodeGeometry = node.geometry as? SCNPlane else {
            return
        }

        nodeGeometry.width = CGFloat(planeAnchor.extent.x)
        nodeGeometry.height = CGFloat(planeAnchor.extent.y)
        node.simdPosition = planeAnchor.center
    }
}


