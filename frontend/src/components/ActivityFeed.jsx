import { useState, useEffect } from 'react';
import './ActivityFeed.css';

/**
 * ActivityFeed - Live activity stream showing recent ticket actions
 */
const ActivityFeed = ({ tickets }) => {
  const [activities, setActivities] = useState([]);

  useEffect(() => {
    // Generate activity feed from ticket data
    const generateActivities = () => {
      const recentActivities = [];

      tickets.forEach(ticket => {
        // Ticket created
        if (ticket.created_at) {
          recentActivities.push({
            id: `created-${ticket.id}`,
            type: 'created',
            icon: '📥',
            text: `New ticket #${ticket.id}`,
            subtext: ticket.title,
            time: new Date(ticket.created_at),
            color: '#667eea'
          });
        }

        // AI generated draft
        if (ticket.ai_generated && ticket.ai_generated_at) {
          recentActivities.push({
            id: `ai-${ticket.id}`,
            type: 'ai_draft',
            icon: '🤖',
            text: `AI drafted response`,
            subtext: `Ticket #${ticket.id} • ${Math.round((ticket.ai_confidence_score || 0) * 100)}% confidence`,
            time: new Date(ticket.ai_generated_at),
            color: '#af52de'
          });
        }

        // First response sent
        if (ticket.first_response_at) {
          recentActivities.push({
            id: `response-${ticket.id}`,
            type: 'response',
            icon: '📧',
            text: `Response sent`,
            subtext: `Ticket #${ticket.id}`,
            time: new Date(ticket.first_response_at),
            color: '#34c759'
          });
        }

        // Ticket resolved
        if (ticket.status === 'resolved' && ticket.resolved_at) {
          recentActivities.push({
            id: `resolved-${ticket.id}`,
            type: 'resolved',
            icon: '✓',
            text: `Ticket resolved`,
            subtext: `#${ticket.id} • ${ticket.resolution_time_minutes || 0}min`,
            time: new Date(ticket.resolved_at),
            color: '#30cfd0'
          });
        }
      });

      // Sort by time (most recent first) and take top 8
      return recentActivities
        .sort((a, b) => b.time - a.time)
        .slice(0, 8);
    };

    setActivities(generateActivities());
  }, [tickets]);

  const getTimeAgo = (date) => {
    const seconds = Math.floor((new Date() - date) / 1000);
    
    if (seconds < 60) return 'just now';
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    if (seconds < 86400) return `${Math.floor(seconds / 3600)}h ago`;
    if (seconds < 604800) return `${Math.floor(seconds / 86400)}d ago`;
    return date.toLocaleDateString();
  };

  return (
    <div className="activity-feed">
      <div className="feed-header">
        <h3>⚡ Recent Activity</h3>
        <span className="live-indicator">
          <span className="pulse-dot"></span>
          Live
        </span>
      </div>

      <div className="activity-list">
        {activities.length === 0 ? (
          <div className="empty-feed">
            <span className="empty-icon">📭</span>
            <p>No recent activity</p>
            <small>Activity will appear here</small>
          </div>
        ) : (
          activities.map((activity, index) => (
            <div 
              key={activity.id} 
              className="activity-item"
              style={{ 
                animationDelay: `${index * 0.05}s`,
                '--activity-color': activity.color
              }}
            >
              <div className="activity-icon" style={{ background: activity.color }}>
                {activity.icon}
              </div>
              <div className="activity-content">
                <div className="activity-text">{activity.text}</div>
                <div className="activity-subtext">{activity.subtext}</div>
              </div>
              <div className="activity-time">{getTimeAgo(activity.time)}</div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};

export default ActivityFeed;
