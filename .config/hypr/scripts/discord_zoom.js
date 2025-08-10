if (window.videoZoomController?.cleanup) {
    window.videoZoomController.cleanup();
}

window.videoZoomController = (function() {
    let currentZoom = 1.0;
    const zoomStep = 0.1;
    const minZoom = 0.5;
    const maxZoom = 3.0;
    
    let video = null;
    let videoSizer = null;
    let originalAspectRatio = null;
    let elementsToAttach = [];
    let isInitialized = false;
    let checkInterval = null;

    function getScreenAspectRatio() {
        const width = window.innerWidth;
        const height = window.innerHeight;
        return width / height;
    }

    function applyZoom(scaleAmount) {
        if (!video) return;
        
        video.style.transform = `scale(${scaleAmount})`;
        video.style.transformOrigin = 'center center';

        const container = video.parentElement;
        if (container) {
            container.style.overflow = 'hidden';
        }

        if (videoSizer) {
            if (scaleAmount !== 1.0) {
                const screenRatio = getScreenAspectRatio();
                videoSizer.style.aspectRatio = `${screenRatio}`;
            } else {
                if (originalAspectRatio && originalAspectRatio !== 'auto') {
                    videoSizer.style.aspectRatio = originalAspectRatio;
                } else {
                    videoSizer.style.aspectRatio = '';
                }
            }
        }
    }

    function setZoom(level) {
        currentZoom = Math.max(minZoom, Math.min(maxZoom, level));
        applyZoom(currentZoom);
    }

    function reset() {
        setZoom(1.0);
    }

    function handleWheel(event) {
        if (!video) return;
        
        const videoRect = video.getBoundingClientRect();
        const isOverVideo = (
            event.clientX >= videoRect.left &&
            event.clientX <= videoRect.right &&
            event.clientY >= videoRect.top &&
            event.clientY <= videoRect.bottom
        );

        if (!isOverVideo) return;

        event.preventDefault();
        event.stopPropagation();

        if (event.deltaY < 0) {
            setZoom(currentZoom + zoomStep);
        } else if (event.deltaY > 0) {
            setZoom(currentZoom - zoomStep);
        }
    }

    function handleResize() {
        if (currentZoom !== 1.0 && videoSizer) {
            const screenRatio = getScreenAspectRatio();
            videoSizer.style.aspectRatio = `${screenRatio}`;
        }
    }

    function cleanup() {
        if (elementsToAttach.length > 0) {
            elementsToAttach.forEach(element => {
                if (element && element.removeEventListener) {
                    element.removeEventListener('wheel', handleWheel);
                }
            });
            elementsToAttach = [];
        }
        window.removeEventListener('resize', handleResize);
        reset();
        isInitialized = false;
    }

    function initialize() {
        video = document.querySelector('video.media-engine-video');
        
        if (!video) {
            return false;
        }

        videoSizer = video.closest('[class*="videoSizer"]') || 
                    document.querySelector('[class*="videoSizer"]');

        originalAspectRatio = videoSizer ? getComputedStyle(videoSizer).aspectRatio : null;

        elementsToAttach = [
            video.parentElement,
            video.parentElement?.parentElement
        ].filter(Boolean);

        elementsToAttach.forEach(element => {
            element.addEventListener('wheel', handleWheel, { passive: false });
        });

        window.addEventListener('resize', handleResize);

        if (currentZoom !== 1.0) {
            applyZoom(currentZoom);
        }

        isInitialized = true;
        return true;
    }

    function checkAndReinitialize() {
        if (video && !document.contains(video)) {
            console.log('Video element was destroyed, cleaning up...');
            cleanup();
        }

        if (!isInitialized || !video) {
            if (initialize()) {
                console.log('Video zoom controller initialized');
            }
        }
    }

    checkInterval = setInterval(checkAndReinitialize, 1000);

    initialize();

    return {
        zoom: setZoom,
        zoomIn: () => setZoom(currentZoom + zoomStep),
        zoomOut: () => setZoom(currentZoom - zoomStep),
        reset: reset,
        getCurrentZoom: () => currentZoom,
        getScreenRatio: getScreenAspectRatio,
        get element() { return video; },
        get videoSizer() { return videoSizer; },
        cleanup: () => {
            if (checkInterval) {
                clearInterval(checkInterval);
                checkInterval = null;
            }
            cleanup();
        }
    };
})();

window.videoZoom = window.videoZoomController;
