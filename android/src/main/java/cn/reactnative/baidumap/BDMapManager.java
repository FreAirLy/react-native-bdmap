package cn.reactnative.baidumap;

import android.util.Log;

import com.baidu.mapapi.map.BaiduMap;
import com.baidu.mapapi.map.LogoPosition;
import com.baidu.mapapi.map.MapStatusUpdateFactory;
import com.baidu.mapapi.map.UiSettings;
import com.baidu.mapapi.model.LatLng;
import com.baidu.mapapi.model.LatLngBounds;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.common.MapBuilder;
import com.baidu.mapapi.map.MapView;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.ViewGroupManager;
import com.facebook.react.uimanager.annotations.ReactProp;

import java.util.Map;

/**
 * Created by tdzl2003 on 4/23/16.
 */
public class BDMapManager extends ViewGroupManager<MapView>  {

    @Override
    public String getName() {
        return "RCTBDMapView";
    }

    @Override
    public Map getExportedCustomDirectEventTypeConstants() {
        return MapBuilder.of(
                "topLoad", MapBuilder.of("registrationName", "onLoad"),
                "topRegionChange", MapBuilder.of("registrationName", "onRegionChange"),
                "topRegionChangeComplete", MapBuilder.of("registrationName", "onRegionChangeComplete")
        );
    }
    @Override
    protected MapView createViewInstance(final ThemedReactContext reactContext) {
        final MapView ret = new MapView(reactContext);
        new BDMapExtraData(reactContext, ret);
        return ret;
    }

    @Override
    public void onDropViewInstance(MapView view) {
        BDMapExtraData.getExtraData(view).onDropViewInstance();
    }
    @ReactProp(name="overlookEnabled")
    public void setOverlookEnabled(MapView view, boolean enabled) {
        BaiduMap mBaiduMap = view.getMap();
        UiSettings mUiSettings = mBaiduMap.getUiSettings();
        //是否禁用仰角
        mUiSettings.setOverlookingGesturesEnabled(enabled);
    }
    //比例尺
    @ReactProp(name="showMapScaleBar")
    public void setShowMapScaleBar(MapView view, boolean enabled) {
        view.showScaleControl(enabled);
    }
    //放大缩小按钮
    @ReactProp(name="showZoomControls")
    public void setShowZoomControls(MapView view, boolean enabled) {
        view.showZoomControls(enabled);
    }
    //双指
    @ReactProp(name="zoomEnabled")
    public void setZoomEnabled(MapView view, boolean enabled) {
        BaiduMap mBaiduMap = view.getMap();
        UiSettings mUiSettings = mBaiduMap.getUiSettings();
        //是否禁用双指
        mUiSettings.setZoomGesturesEnabled(enabled);
    }
    @ReactProp(name="logoPosition")
    public void setLogoPosition(MapView view, String region) {
        if(region != null){
            LogoPosition position ;
            switch (region){
                case "leftTop":
                    position = LogoPosition.logoPostionleftTop;
                    break;
                case "centerBottom":
                    position = LogoPosition.logoPostionCenterBottom;
                    break;
                case "centerTop":
                    position = LogoPosition.logoPostionCenterTop;
                    break;
                case "rightBottom":
                    position = LogoPosition.logoPostionRightBottom;
                    break;
                case "rightTop":
                    position = LogoPosition.logoPostionRightTop;
                    break;
                default:
                    position = LogoPosition.logoPostionleftBottom;
                    break;
            }
            view.setLogoPosition(position);
        }else{
            view.setLogoPosition(LogoPosition.logoPostionleftBottom);
        }
    }
    @ReactProp(name="mapPadding")
    public void setMapPadding(MapView view, ReadableMap region) {
        if(region != null){
            int paddingLeft = region.hasKey("paddingLeft") ? region.getInt("paddingLeft"):0;
            int paddingTop = region.hasKey("paddingTop") ? region.getInt("paddingTop"):0;
            int paddingRight = region.hasKey("paddingRight") ? region.getInt("paddingRight"):0;
            int paddingBottom = region.hasKey("paddingBottom") ? region.getInt("paddingBottom"):0;
            Log.e("tt","paddingLeft:"+paddingLeft+",paddingTop:"+paddingTop+",paddingRight:"+paddingRight+",paddingBottom:"+paddingBottom);
            view.getMap().setPadding(paddingLeft, paddingTop, paddingRight, paddingBottom);
        }else{
            view.setLogoPosition(LogoPosition.logoPostionleftBottom);
        }

    }

    @ReactProp(name="showsUserLocation")
    public void setEnableMyLocation(MapView view, boolean enabled) {
        view.getMap().setMyLocationEnabled(enabled);
    }

    @ReactProp(name="region")
    public void setRegion(MapView view, ReadableMap region) {
        if (region == null) {
            return;
        }
        double longitude = region.getDouble("longitude");
        double latitude = region.getDouble("latitude");
        double longitudeDelta = region.hasKey("longitudeDelta") ? region.getDouble("longitudeDelta") / 2 : 0;
        double latitudeDelta = region.hasKey("latitudeDelta") ? region.getDouble("latitudeDelta") / 2 : 0;

        view.getMap().animateMapStatus(MapStatusUpdateFactory.newLatLngBounds(new LatLngBounds.Builder()
                .include(new LatLng(latitude - latitudeDelta, longitude - longitudeDelta))
                .include(new LatLng(latitude + latitudeDelta, longitude + longitudeDelta))
                .build()));
    }

    @ReactProp(name="traceData")
    public void setTraceData(MapView view, ReadableArray arr) {
        BDMapExtraData.getExtraData(view).setTraceData(arr);
    }

    @ReactProp(name="annotations")
    public void setAnnotations(MapView view, ReadableArray arr) {
        BDMapExtraData.getExtraData(view).setAnnotations(arr);
    }
}
