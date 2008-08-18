using System.Windows;
using System.Windows.Input;
using IronNails.Library;
using IronNails.View;

namespace IronNails.ViewModels
{
    /// <summary>
    /// The ViewModel we will be using in the MainWindow view
    /// </summary>
    public class MainWindowViewModel : ViewModel
    {
        private ICommand _showMessage;

        public ICommand ShowMessage
        {
            get
            {
                if (_showMessage == null)
                    _showMessage = new DelegateCommand(() => MessageBox.Show("From Strong Typed Command"));
                return _showMessage;
            }
            set
            {
                if(_showMessage == value) return;
                _showMessage = value;
                OnPropertyChanged("ShowMessage");
            }
        }
    }
}