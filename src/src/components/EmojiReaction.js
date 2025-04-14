import React, { useState, useEffect } from 'react';
import { Box, Tooltip, IconButton, Badge, Paper, Zoom, Popover } from '@mui/material';
import ThumbUpAltIcon from '@mui/icons-material/ThumbUpAlt';
import ThumbDownAltIcon from '@mui/icons-material/ThumbDownAlt';
import MoodIcon from '@mui/icons-material/Mood';
import SentimentVeryDissatisfiedIcon from '@mui/icons-material/SentimentVeryDissatisfied';
import FavoriteIcon from '@mui/icons-material/Favorite';
import CelebrationIcon from '@mui/icons-material/Celebration';
import AddReactionIcon from '@mui/icons-material/AddReaction';

/**
 * Quick feedback component with emoji reactions
 * Allows users to react to content with emoji/reactions
 * 
 * @param {object} props Component properties
 * @param {string} props.id Unique identifier for the content being reacted to
 * @param {object} props.initialCounts Initial reaction counts
 * @param {function} props.onReaction Callback when user reacts
 * @param {string} props.position Position of the reaction bar ('top', 'bottom', 'left', 'right')
 * @param {boolean} props.compact Show in compact mode
 * @param {string} props.className Additional CSS classes
 */
const EmojiReaction = ({
  id,
  initialCounts = { like: 0, love: 0, celebrate: 0, smile: 0, sad: 0, dislike: 0 },
  onReaction = () => {},
  position = 'bottom',
  compact = false,
  className = '',
}) => {
  const [reactions, setReactions] = useState(initialCounts);
  const [userReaction, setUserReaction] = useState(null);
  const [anchorEl, setAnchorEl] = useState(null);
  const [showPopover, setShowPopover] = useState(false);
  const [animateIcon, setAnimateIcon] = useState(null);

  // Reaction types configuration
  const reactionTypes = {
    like: { 
      icon: <ThumbUpAltIcon />, 
      label: 'Like',
      color: '#3275e3'
    },
    love: { 
      icon: <FavoriteIcon />, 
      label: 'Love',
      color: '#e33265'
    },
    celebrate: { 
      icon: <CelebrationIcon />, 
      label: 'Celebrate',
      color: '#e38832'
    },
    smile: { 
      icon: <MoodIcon />, 
      label: 'Happy',
      color: '#32e373'
    },
    sad: { 
      icon: <SentimentVeryDissatisfiedIcon />, 
      label: 'Sad',
      color: '#8832e3'
    },
    dislike: { 
      icon: <ThumbDownAltIcon />, 
      label: 'Dislike',
      color: '#535353'
    }
  };

  // Load saved reactions from localStorage
  useEffect(() => {
    const savedReaction = localStorage.getItem(`reaction-${id}`);
    if (savedReaction) {
      setUserReaction(savedReaction);
    }
  }, [id]);

  // Handle reaction click
  const handleReaction = (reactionType) => {
    setShowPopover(false);
    
    // If already reacted with this type, remove the reaction
    if (userReaction === reactionType) {
      const updatedReactions = { 
        ...reactions, 
        [reactionType]: Math.max(0, reactions[reactionType] - 1)
      };
      
      setReactions(updatedReactions);
      setUserReaction(null);
      localStorage.removeItem(`reaction-${id}`);
      
      // Notify parent component
      onReaction(reactionType, false, updatedReactions);
      return;
    }
    
    // If previously reacted with different type, remove the old reaction
    if (userReaction) {
      setReactions({
        ...reactions,
        [userReaction]: Math.max(0, reactions[userReaction] - 1),
        [reactionType]: (reactions[reactionType] || 0) + 1
      });
    } else {
      // First reaction
      setReactions({
        ...reactions,
        [reactionType]: (reactions[reactionType] || 0) + 1
      });
    }
    
    // Set new reaction and save to localStorage
    setUserReaction(reactionType);
    setAnimateIcon(reactionType);
    localStorage.setItem(`reaction-${id}`, reactionType);
    
    // Notify parent component
    onReaction(reactionType, true, reactions);
    
    // Remove animation class after animation completes
    setTimeout(() => {
      setAnimateIcon(null);
    }, 1000);
  };

  // Open reaction selector
  const handleOpenReactions = (event) => {
    setAnchorEl(event.currentTarget);
    setShowPopover(true);
  };

  // Close reaction selector
  const handleCloseReactions = () => {
    setShowPopover(false);
  };

  // Calculate total reactions
  const totalReactions = Object.values(reactions).reduce((sum, count) => sum + count, 0);

  // Determine layout based on position
  const getFlexDirection = () => {
    switch (position) {
      case 'top': return 'column';
      case 'bottom': return 'column-reverse';
      case 'left': return 'row';
      case 'right': return 'row-reverse';
      default: return 'row';
    }
  };

  // Render the add reaction button (or the active reaction if user already reacted)
  const renderReactionButton = () => {
    if (userReaction) {
      const reaction = reactionTypes[userReaction];
      return (
        <Tooltip title={`You reacted: ${reaction.label}`}>
          <IconButton 
            onClick={handleOpenReactions}
            className={animateIcon === userReaction ? 'animate-reaction' : ''}
            sx={{ 
              color: reaction.color,
              transition: 'transform 0.2s',
              '&:hover': { transform: 'scale(1.1)' },
              animation: animateIcon === userReaction ? 'pulse 0.4s 2' : 'none'
            }}
          >
            {reaction.icon}
          </IconButton>
        </Tooltip>
      );
    }
    
    return (
      <Tooltip title="Add Reaction">
        <IconButton onClick={handleOpenReactions}>
          <AddReactionIcon />
        </IconButton>
      </Tooltip>
    );
  };

  // Render reaction counts
  const renderReactionCounts = () => {
    if (totalReactions === 0) return null;
    
    return (
      <Tooltip 
        title={
          <Box>
            {Object.entries(reactions).map(([type, count]) => (
              count > 0 && (
                <Box key={type} sx={{ display: 'flex', alignItems: 'center', mb: 0.5 }}>
                  <Box sx={{ mr: 1, color: reactionTypes[type].color }}>
                    {reactionTypes[type].icon}
                  </Box>
                  {count} {reactionTypes[type].label}
                </Box>
              )
            ))}
          </Box>
        }
      >
        <Badge 
          badgeContent={totalReactions} 
          color="primary"
          sx={{ cursor: 'pointer' }}
        >
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              minWidth: 24,
              minHeight: 24,
            }}
          >
            {/* Show the most used reaction icon if any */}
            {Object.entries(reactions)
              .sort(([,a], [,b]) => b - a)
              .filter(([,count]) => count > 0)
              .slice(0, 1)
              .map(([type]) => (
                <Box key={type} sx={{ color: reactionTypes[type].color }}>
                  {reactionTypes[type].icon}
                </Box>
              ))
            }
          </Box>
        </Badge>
      </Tooltip>
    );
  };

  return (
    <Box 
      className={`emoji-reaction ${className}`}
      sx={{ 
        display: 'flex', 
        flexDirection: getFlexDirection(),
        alignItems: 'center',
        justifyContent: 'center',
        gap: 1,
        my: 1
      }}
    >
      {renderReactionButton()}
      
      {!compact && renderReactionCounts()}
      
      <Popover
        open={showPopover}
        anchorEl={anchorEl}
        onClose={handleCloseReactions}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'center',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'center',
        }}
      >
        <Paper 
          elevation={3}
          sx={{ 
            display: 'flex',
            p: 1,
            borderRadius: 4,
            backgroundColor: theme => theme.palette.background.paper,
          }}
        >
          {Object.entries(reactionTypes).map(([type, { icon, label, color }]) => (
            <Tooltip key={type} title={label} arrow>
              <IconButton
                onClick={() => handleReaction(type)}
                sx={{ 
                  color: userReaction === type ? color : 'text.secondary',
                  backgroundColor: userReaction === type ? 'rgba(0, 0, 0, 0.04)' : 'transparent',
                  transition: 'transform 0.2s',
                  '&:hover': { 
                    color: color,
                    transform: 'scale(1.2) translateY(-2px)'
                  },
                }}
              >
                {icon}
              </IconButton>
            </Tooltip>
          ))}
        </Paper>
      </Popover>

      <style jsx global>{`
        @keyframes pulse {
          0% { transform: scale(1); }
          50% { transform: scale(1.3); }
          100% { transform: scale(1); }
        }
      `}</style>
    </Box>
  );
};

export default EmojiReaction;