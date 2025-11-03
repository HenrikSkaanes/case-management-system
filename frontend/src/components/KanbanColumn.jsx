import { useState } from 'react';
import TicketCard from './TicketCard';
import './KanbanColumn.css';

/**
 * KanbanColumn - A single column in the Kanban board
 * 
 * Displays tickets for a specific status
 * Handles drop events to update ticket status
 * Supports dynamic styling with gradients
 */
const KanbanColumn = ({ status, title, tickets, onUpdateTicket, onEditTicket, onDeleteTicket, onRespond, icon, color, gradient }) => {
  const [isDragOver, setIsDragOver] = useState(false);

  const handleDragOver = (e) => {
    e.preventDefault();
    setIsDragOver(true);
  };

  const handleDragLeave = () => {
    setIsDragOver(false);
  };

  const handleDrop = async (e) => {
    e.preventDefault();
    setIsDragOver(false);

    const ticketId = e.dataTransfer.getData('ticketId');
    if (ticketId) {
      // Map the column status to the actual ticket status
      // For consolidated columns, use the first status in the list
      const statusMap = {
        'new': 'new',
        'ai_processing': 'ai_draft', // Default to ai_draft for AI Processing column
        'in_progress': 'in_progress',
        'awaiting': 'awaiting_customer',
        'resolved': 'resolved'
      };
      await onUpdateTicket(parseInt(ticketId), { status: statusMap[status] || status });
    }
  };

  const getStatusClass = (status) => {
    switch (status) {
      case 'new':
        return 'status-new';
      case 'ai_processing':
        return 'status-ai-processing';
      case 'in_progress':
        return 'status-progress';
      case 'awaiting':
        return 'status-awaiting';
      case 'resolved':
        return 'status-resolved';
      default:
        return '';
    }
  };

  return (
    <div 
      className={`kanban-column ${getStatusClass(status)} ${isDragOver ? 'drag-over' : ''}`}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      style={{ 
        '--column-color': color,
        '--column-gradient': gradient
      }}
    >
      <div className="column-header" style={{ background: gradient }}>
        <div className="column-title">
          <span className="column-icon">{icon}</span>
          <h2>{title}</h2>
        </div>
        <span className="column-count">{tickets.length}</span>
      </div>

      <div className="column-content">
        {tickets.length === 0 ? (
          <div className="empty-column">
            <p>No tickets</p>
            <small>Drag tickets here</small>
          </div>
        ) : (
          tickets.map((ticket) => (
            <TicketCard
              key={ticket.id}
              ticket={ticket}
              onEdit={onEditTicket}
              onDelete={onDeleteTicket}
              onRespond={onRespond}
            />
          ))
        )}
      </div>
    </div>
  );
};

export default KanbanColumn;
