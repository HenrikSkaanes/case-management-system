import { useState, useEffect } from 'react'
import KanbanColumn from './components/KanbanColumn'
import TicketModal from './components/TicketModal'
import { fetchTickets, createTicket, updateTicket, deleteTicket } from './services/api'
import './App.css'

/**
 * Main App Component - Enterprise Case Management System
 * 
 * Features:
 * - Kanban board with drag & drop
 * - Filter by category and priority
 * - Search tickets
 * - Create, edit, delete tickets
 * - Professional UI
 */
function App() {
  const [tickets, setTickets] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [searchTerm, setSearchTerm] = useState('')
  const [filterCategory, setFilterCategory] = useState('')
  const [filterPriority, setFilterPriority] = useState('')
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [editingTicket, setEditingTicket] = useState(null)

  // Load tickets on mount
  useEffect(() => {
    loadTickets()
  }, [])

  const loadTickets = async () => {
    try {
      setLoading(true)
      setError(null)
      const data = await fetchTickets()
      setTickets(data)
    } catch (err) {
      setError('Failed to load tickets. Make sure the backend is running.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }

  const handleCreateTicket = async (ticketData) => {
    try {
      const newTicket = await createTicket(ticketData)
      setTickets(prev => [newTicket, ...prev])
    } catch (err) {
      alert('Failed to create ticket')
      console.error(err)
    }
  }

  const handleUpdateTicket = async (ticketId, updates) => {
    try {
      const updatedTicket = await updateTicket(ticketId, updates)
      setTickets(prev =>
        prev.map(ticket => (ticket.id === ticketId ? updatedTicket : ticket))
      )
    } catch (err) {
      alert('Failed to update ticket')
      console.error(err)
    }
  }

  const handleDeleteTicket = async (ticketId) => {
    try {
      await deleteTicket(ticketId)
      setTickets(prev => prev.filter(ticket => ticket.id !== ticketId))
    } catch (err) {
      alert('Failed to delete ticket')
      console.error(err)
    }
  }

  const handleEditTicket = (ticket) => {
    setEditingTicket(ticket)
    setIsModalOpen(true)
  }

  const handleModalSubmit = async (formData) => {
    if (editingTicket) {
      await handleUpdateTicket(editingTicket.id, formData)
    } else {
      await handleCreateTicket(formData)
    }
    setEditingTicket(null)
  }

  const handleModalClose = () => {
    setIsModalOpen(false)
    setEditingTicket(null)
  }

  // Filter and search tickets
  const filteredTickets = tickets.filter(ticket => {
    const matchesSearch = ticket.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         ticket.description?.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesCategory = !filterCategory || ticket.category === filterCategory
    const matchesPriority = !filterPriority || ticket.priority === filterPriority
    return matchesSearch && matchesCategory && matchesPriority
  })

  // Group tickets by status
  const ticketsByStatus = {
    new: filteredTickets.filter(t => t.status === 'new'),
    in_progress: filteredTickets.filter(t => t.status === 'in_progress'),
    done: filteredTickets.filter(t => t.status === 'done'),
  }

  // Get unique categories
  const categories = [...new Set(tickets.map(t => t.category))].sort()

  if (loading) {
    return (
      <div className="App">
        <div className="loading-container">
          <div className="spinner"></div>
          <p>Loading tickets...</p>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="App">
        <div className="error-container">
          <h2>⚠️ Error</h2>
          <p>{error}</p>
          <button onClick={loadTickets} className="btn-retry">Retry</button>
        </div>
      </div>
    )
  }

  return (
    <div className="App">
      <header className="app-header">
        <div className="header-content">
          <div className="header-left">
            <h1>📋 Case Management System</h1>
            <p className="subtitle">Enterprise Ticketing & Support Platform</p>
          </div>
          <button 
            className="btn-create"
            onClick={() => setIsModalOpen(true)}
          >
            ➕ New Ticket
          </button>
        </div>

        <div className="toolbar">
          <div className="search-box">
            <span className="search-icon">🔍</span>
            <input
              type="text"
              placeholder="Search tickets..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <select
            value={filterCategory}
            onChange={(e) => setFilterCategory(e.target.value)}
            className="filter-select"
          >
            <option value="">All Categories</option>
            {categories.map(cat => (
              <option key={cat} value={cat}>{cat}</option>
            ))}
          </select>

          <select
            value={filterPriority}
            onChange={(e) => setFilterPriority(e.target.value)}
            className="filter-select"
          >
            <option value="">All Priorities</option>
            <option value="low">🟢 Low</option>
            <option value="medium">🟡 Medium</option>
            <option value="high">🔴 High</option>
          </select>

          <button onClick={loadTickets} className="btn-refresh" title="Refresh">
            🔄
          </button>
        </div>

        <div className="stats-bar">
          <div className="stat">
            <span className="stat-value">{tickets.length}</span>
            <span className="stat-label">Total Tickets</span>
          </div>
          <div className="stat">
            <span className="stat-value">{ticketsByStatus.new.length}</span>
            <span className="stat-label">New</span>
          </div>
          <div className="stat">
            <span className="stat-value">{ticketsByStatus.in_progress.length}</span>
            <span className="stat-label">In Progress</span>
          </div>
          <div className="stat">
            <span className="stat-value">{ticketsByStatus.done.length}</span>
            <span className="stat-label">Completed</span>
          </div>
        </div>
      </header>

      <main className="kanban-board">
        <KanbanColumn
          status="new"
          title="New"
          icon="📥"
          tickets={ticketsByStatus.new}
          onUpdateTicket={handleUpdateTicket}
          onEditTicket={handleEditTicket}
          onDeleteTicket={handleDeleteTicket}
        />
        <KanbanColumn
          status="in_progress"
          title="In Progress"
          icon="⚙️"
          tickets={ticketsByStatus.in_progress}
          onUpdateTicket={handleUpdateTicket}
          onEditTicket={handleEditTicket}
          onDeleteTicket={handleDeleteTicket}
        />
        <KanbanColumn
          status="done"
          title="Done"
          icon="✅"
          tickets={ticketsByStatus.done}
          onUpdateTicket={handleUpdateTicket}
          onEditTicket={handleEditTicket}
          onDeleteTicket={handleDeleteTicket}
        />
      </main>

      <TicketModal
        isOpen={isModalOpen}
        onClose={handleModalClose}
        onSubmit={handleModalSubmit}
        ticket={editingTicket}
      />
    </div>
  )
}

export default App
