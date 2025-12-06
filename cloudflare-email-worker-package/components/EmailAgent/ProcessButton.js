export default function ProcessButton({ onClick, processing }) {
  return (
    <button
      onClick={onClick}
      disabled={processing}
      className={`w-full py-3 px-4 rounded-lg font-medium transition-colors ${
        processing
          ? 'bg-gray-300 dark:bg-gray-600 text-gray-500 dark:text-gray-400 cursor-not-allowed'
          : 'bg-blue-600 hover:bg-blue-700 text-white'
      }`}
    >
      {processing ? (
        <div className="flex items-center justify-center">
          <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white mr-2"></div>
          Processing...
        </div>
      ) : (
        'Process Emails Now'
      )}
    </button>
  );
}
