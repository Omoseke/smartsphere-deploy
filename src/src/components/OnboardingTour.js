import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogContentText,
  DialogTitle,
  Fade,
  IconButton,
  Paper,
  Popper,
  Typography,
  useTheme,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import NavigateNextIcon from '@mui/icons-material/NavigateNext';
import NavigateBeforeIcon from '@mui/icons-material/NavigateBefore';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';

/**
 * Interactive Onboarding Tour with animated tooltips
 * Provides guided tour through application features with step-by-step instructions
 * 
 * @param {Object} props Component properties
 * @param {boolean} props.open Whether the tour is active
 * @param {function} props.onClose Callback when the tour is closed or completed
 * @param {Array} props.steps Array of step objects defining the tour
 * @param {string} props.tourId Unique ID for storing tour completion in localStorage
 */
const OnboardingTour = ({
  open = false,
  onClose,
  steps = [],
  tourId = 'app-tour',
}) => {
  const theme = useTheme();
  const [isActive, setIsActive] = useState(open);
  const [currentStep, setCurrentStep] = useState(0);
  const [welcomeOpen, setWelcomeOpen] = useState(true);
  const [stepElement, setStepElement] = useState(null);
  const [completedSteps, setCompletedSteps] = useState({});
  
  // Track if a tour has been completed before
  useEffect(() => {
    const tourCompleted = localStorage.getItem(`tour-${tourId}-completed`);
    if (tourCompleted) {
      setCompletedSteps(JSON.parse(tourCompleted));
    }
  }, [tourId]);
  
  // Effect to set active state when open prop changes
  useEffect(() => {
    setIsActive(open);
    if (open) {
      setCurrentStep(0);
      setWelcomeOpen(true);
    }
  }, [open]);
  
  // Handle welcome dialog close
  const handleWelcomeClose = () => {
    setWelcomeOpen(false);
    if (steps.length > 0) {
      highlightStep(0);
    }
  };
  
  // Handle skipping the entire tour
  const handleSkipTour = () => {
    setIsActive(false);
    if (onClose) onClose('skipped');
  };
  
  // Handle completing the tour
  const handleCompleteTour = () => {
    const allCompleted = {...completedSteps};
    steps.forEach((step, index) => {
      allCompleted[index] = true;
    });
    
    localStorage.setItem(`tour-${tourId}-completed`, JSON.stringify(allCompleted));
    setCompletedSteps(allCompleted);
    setIsActive(false);
    
    if (onClose) onClose('completed');
  };
  
  // Go to next step
  const handleNextStep = () => {
    const nextIndex = currentStep + 1;
    if (nextIndex < steps.length) {
      // Mark current step as completed
      const updated = {...completedSteps, [currentStep]: true};
      setCompletedSteps(updated);
      localStorage.setItem(`tour-${tourId}-completed`, JSON.stringify(updated));
      
      setCurrentStep(nextIndex);
      highlightStep(nextIndex);
    } else {
      handleCompleteTour();
    }
  };
  
  // Go to previous step
  const handlePrevStep = () => {
    const prevIndex = currentStep - 1;
    if (prevIndex >= 0) {
      setCurrentStep(prevIndex);
      highlightStep(prevIndex);
    }
  };
  
  // Find and highlight the element for the current step
  const highlightStep = (stepIndex) => {
    const step = steps[stepIndex];
    if (!step) return;
    
    // Support both selector string and ref object
    let element = null;
    if (typeof step.target === 'string') {
      element = document.querySelector(step.target);
    } else if (step.target.current) {
      element = step.target.current;
    }
    
    if (element) {
      // Scroll element into view if needed
      const rect = element.getBoundingClientRect();
      const isVisible = (
        rect.top >= 0 &&
        rect.left >= 0 &&
        rect.bottom <= window.innerHeight &&
        rect.right <= window.innerWidth
      );
      
      if (!isVisible) {
        element.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
      
      // Add a temporary highlight class to the target element
      element.classList.add('onboarding-highlight');
      setStepElement(element);
      
      // Clean up highlight when moving to another step
      return () => {
        element.classList.remove('onboarding-highlight');
      };
    }
  };
  
  // Effect to highlight current step
  useEffect(() => {
    if (isActive && !welcomeOpen && steps.length > 0) {
      const cleanup = highlightStep(currentStep);
      return () => {
        if (cleanup) cleanup();
      };
    }
  }, [currentStep, isActive, welcomeOpen, steps]);
  
  // Clean up when component unmounts
  useEffect(() => {
    return () => {
      if (stepElement) {
        stepElement.classList.remove('onboarding-highlight');
      }
    };
  }, [stepElement]);
  
  // Current step data
  const currentStepData = steps[currentStep] || {};
  
  // Check if we're at the last step
  const isLastStep = currentStep === steps.length - 1;
  
  if (!isActive) return null;
  
  return (
    <>
      {/* Welcome Dialog */}
      <Dialog
        open={welcomeOpen}
        onClose={handleWelcomeClose}
        maxWidth="sm"
        PaperProps={{
          elevation: 5,
          sx: {
            borderRadius: 2,
            px: 1
          }
        }}
      >
        <DialogTitle sx={{ pb: 1 }}>
          Welcome to the SmartSphere Tour!
          <IconButton
            aria-label="close"
            onClick={handleSkipTour}
            sx={{
              position: 'absolute',
              right: 8,
              top: 8,
              color: (theme) => theme.palette.grey[500],
            }}
          >
            <CloseIcon />
          </IconButton>
        </DialogTitle>
        <DialogContent>
          <DialogContentText>
            This quick tour will guide you through the key features of SmartSphere. 
            Learn how to navigate the dashboard, manage deployments, and customize 
            your experience.
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ pb: 2, px: 3 }}>
          <Button onClick={handleSkipTour} color="inherit">
            Skip Tour
          </Button>
          <Button 
            onClick={handleWelcomeClose} 
            variant="contained" 
            disableElevation
            endIcon={<NavigateNextIcon />}
          >
            Start Tour
          </Button>
        </DialogActions>
      </Dialog>
      
      {/* Step Tooltip */}
      {!welcomeOpen && stepElement && (
        <Popper
          open={true}
          anchorEl={stepElement}
          placement={currentStepData.placement || 'bottom'}
          transition
          modifiers={[
            {
              name: 'offset',
              options: {
                offset: [0, 12],
              },
            },
          ]}
        >
          {({ TransitionProps }) => (
            <Fade {...TransitionProps} timeout={350}>
              <Paper
                elevation={6}
                sx={{
                  maxWidth: 340,
                  p: 2,
                  borderRadius: 2,
                  bgcolor: theme.palette.background.paper,
                  border: `1px solid ${theme.palette.primary.main}`,
                  position: 'relative',
                  '&:after': {
                    content: '""',
                    position: 'absolute',
                    width: 12,
                    height: 12,
                    bgcolor: theme.palette.background.paper,
                    border: '1px solid',
                    borderColor: `${theme.palette.primary.main} transparent transparent ${theme.palette.primary.main}`,
                    transform: 'rotate(45deg)',
                    ...getArrowPosition(currentStepData.placement),
                  }
                }}
              >
                <Box sx={{ position: 'relative' }}>
                  <Typography variant="subtitle1" fontWeight="bold" gutterBottom>
                    {currentStep + 1}. {currentStepData.title}
                  </Typography>
                  <Typography variant="body2" paragraph sx={{ mb: 2 }}>
                    {currentStepData.content}
                  </Typography>
                  
                  <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                    <Button 
                      onClick={handlePrevStep}
                      disabled={currentStep === 0}
                      startIcon={<NavigateBeforeIcon />}
                      size="small"
                    >
                      Back
                    </Button>
                    
                    <Box>
                      <Typography variant="caption" sx={{ mr: 1 }}>
                        {currentStep + 1} of {steps.length}
                      </Typography>
                    </Box>
                    
                    <Button 
                      onClick={handleNextStep}
                      variant="contained"
                      disableElevation
                      size="small"
                      endIcon={isLastStep ? <CheckCircleOutlineIcon /> : <NavigateNextIcon />}
                      color={isLastStep ? 'success' : 'primary'}
                    >
                      {isLastStep ? 'Finish' : 'Next'}
                    </Button>
                  </Box>
                </Box>
              </Paper>
            </Fade>
          )}
        </Popper>
      )}
      
      {/* Highlight overlay styles */}
      <style jsx global>{`
        .onboarding-highlight {
          position: relative;
          z-index: 1501;
          box-shadow: 0 0 0 4px ${theme.palette.primary.main}!important;
          border-radius: 4px;
          animation: pulse-border 1.5s infinite;
        }
        
        @keyframes pulse-border {
          0% {
            box-shadow: 0 0 0 0 rgba(25, 118, 210, 0.4), 0 0 0 4px ${theme.palette.primary.main};
          }
          70% {
            box-shadow: 0 0 0 10px rgba(25, 118, 210, 0), 0 0 0 4px ${theme.palette.primary.main};
          }
          100% {
            box-shadow: 0 0 0 0 rgba(25, 118, 210, 0), 0 0 0 4px ${theme.palette.primary.main};
          }
        }
      `}</style>
    </>
  );
};

// Helper to calculate arrow position based on placement
const getArrowPosition = (placement) => {
  switch (placement) {
    case 'top':
      return { bottom: -7, left: 'calc(50% - 6px)', transform: 'rotate(-135deg)' };
    case 'bottom':
      return { top: -7, left: 'calc(50% - 6px)', transform: 'rotate(45deg)' };
    case 'left':
      return { right: -7, top: 'calc(50% - 6px)', transform: 'rotate(-45deg)' };
    case 'right':
      return { left: -7, top: 'calc(50% - 6px)', transform: 'rotate(135deg)' };
    default:
      return { top: -7, left: 'calc(50% - 6px)', transform: 'rotate(45deg)' };
  }
};

export default OnboardingTour;