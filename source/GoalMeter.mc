using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Application as App;

class GoalMeter extends Ui.Drawable {

	private var mSide; // :left, :right.
	private var mShape; // :arc, :line.
	private var mStroke; // Stroke width.
	private var mHeight; // Total height of meter.
	private var mSeparator; // Stroke width of separator bars.

	private var mCurrentValue = 0;
	private var mMaxValue = 100;

	private var mLastColour = null;

	private const SEGMENT_SCALES = [1, 10, 100, 1000, 10000];
	private const MIN_WHOLE_SEGMENT_HEIGHT = 5;

	function initialize(params) {
		Drawable.initialize(params);

		mSide = params[:side];
		mShape = params[:shape];
		mStroke = params[:stroke];
		mHeight = params[:height];
		mSeparator = params[:separator];
	}
	
	function draw(dc) {
		var segments = getSegments();

		dc.setPenWidth(mStroke);
		
		var bottom = dc.getHeight() - ((dc.getHeight() - mHeight) / 2);
		var height, fillHeight;

		for (var i = 0; i < segments.size(); ++i) {
			height = segments[i][:height];
			fillHeight = segments[i][:fillHeight];

			// Fully filled segment.
			if (fillHeight == height) {

				drawSegment(dc, bottom, height, App.getApp().getProperty("ThemeColour"));
			
			// Partially filled segment.
			} else if (fillHeight > 0) {
				
				drawSegment(dc, bottom, fillHeight, App.getApp().getProperty("ThemeColour"));
				drawSegment(dc, bottom - fillHeight, height - fillHeight, App.getApp().getProperty("MeterBackgroundColour"));

			// Empty segment.
			} else {

				drawSegment(dc, bottom, height, App.getApp().getProperty("MeterBackgroundColour"));
			}

			// Separator.
			bottom -= height + mSeparator;
		}

		// drawSegment() may set clip.
		dc.clearClip();

		// Clear mLastColour to force it to be set at the beginning of the next draw cycle, or else full goal meter draws as
		// empty on second draw cycle.
		mLastColour = null;
	}

	function drawSegment(dc, bottom, height, colour) {

		// Set DC colour if different from current DC colour.
		if (colour != mLastColour) {
			mLastColour = colour;
			dc.setColor(colour, Graphics.COLOR_TRANSPARENT);
		}

		var halfDCWidth = dc.getWidth() / 2.0;
		var halfDCHeight = dc.getHeight() / 2.0;	

		var left;
		var top = bottom - height;
		var radius = halfDCWidth - (mStroke / 2.0);

		var theta = Math.asin((mHeight / 2.0) / (halfDCWidth - mStroke));
		theta /= (Math.PI / 180); // Half angle subtended by full meter arc, in degrees.
		
		var direction;
		var start;
		var end;

		if (mSide == :left) {
			left = 0;
			direction = Graphics.ARC_CLOCKWISE;
			start = 180 + theta; // 180 degrees: 9 o'clock.
			end = 180 - theta;
		} else {
			left = halfDCWidth;
			direction = Graphics.ARC_COUNTER_CLOCKWISE;
			start = 360 - theta; // 0 or 360 degrees: 3 o'clock.
			end = 0 + theta;
		}

		if (mShape == :arc) {
			dc.setClip(left, top, halfDCWidth, height);
			//dc.drawCircle(halfDCWidth, halfDCHeight, radius); 
			dc.drawArc(halfDCWidth, halfDCHeight, radius, direction, start, end);
		} else {
			// TODO.
		}
	}

	function setValues(current, max) {
		mCurrentValue = current;
		mMaxValue = max;
	}

	// Return array of dictionaries, one per segment. Each dictionary describes height and fill height of segment.
	// Last segment may be partial segment; if so, ensure its height is at least 1 pixel.
	// Segment heights rounded to nearest pixel, so neighbouring whole segments may differ in height by a pixel.
	function getSegments() {
		var segmentScale = getSegmentScale(); // Value each whole segment represents.

		var numSegments = mMaxValue * 1.0 / segmentScale; // Including any partial. Force floating-point division.
		var numSeparators = Math.ceil(numSegments) - 1;

		var totalSegmentHeight = mHeight - (numSeparators * mSeparator); // Subtract total separator height from full height.		
		var segmentHeight = totalSegmentHeight * 1.0 / numSegments; // Force floating-point division.
		Sys.println("segmentHeight " + segmentHeight);

		var remainingFillHeight = Math.round((mCurrentValue * 1.0 / mMaxValue) * totalSegmentHeight);
		Sys.println("remainingFillHeight " + remainingFillHeight);

		var segments = new [Math.ceil(numSegments)];
		var start, end, height, fillHeight;

		for (var i = 0; i < segments.size(); ++i) {
			start = Math.round(i * segmentHeight);
			end = Math.round((i + 1) * segmentHeight);

			// Last segment is partial.
			if (end > totalSegmentHeight) {
				end = totalSegmentHeight;
			}

			height = end - start;

			// Fully filled segment.
			if (remainingFillHeight > height) {
				fillHeight = height;

			// Partially filled segment.
			} else if (remainingFillHeight > 0) {
				fillHeight = remainingFillHeight;

			// Empty segment.
			} else {
				fillHeight = 0;
			}

			segments[i] = {};
			segments[i][:height] = height;
			segments[i][:fillHeight] = fillHeight;
			Sys.println("segment " + i + " height " + segments[i][:height] + " fillHeight " + segments[i][:fillHeight]);

			remainingFillHeight -= height;
			Sys.println("remainingFillHeight " + remainingFillHeight);
		}

		return segments;
	}

	// Determine what value each whole segment represents.
	// Try each scale in SEGMENT_SCALES array, until MIN_SEGMENT_HEIGHT is breached.
	function getSegmentScale() {
		var segmentScale;

		var tryScaleIndex = 0;		
		var segmentHeight;
		var numSegments;
		var numSeparators;
		var totalSegmentHeight;

		do {
			segmentScale = SEGMENT_SCALES[tryScaleIndex];

			numSegments = mMaxValue * 1.0 / segmentScale;
			numSeparators = Math.ceil(numSegments);
			totalSegmentHeight = mHeight - (numSeparators * mSeparator);
			segmentHeight = Math.floor(totalSegmentHeight / numSegments);

			tryScaleIndex++;	
		} while (segmentHeight <= MIN_WHOLE_SEGMENT_HEIGHT);

		Sys.println("scale " + segmentScale);
		return segmentScale;
	}
}