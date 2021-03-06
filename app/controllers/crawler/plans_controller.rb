class Crawler::PlansController < Crawler::BaseController
  before_action :set_crawler_plan, only: [:today_finish, :flush_page, :exce, :auto_exce, :show, :edit, :update, :destroy]

  @@exec_histroy = {}
  # GET /crawler/plans
  # GET /crawler/plans.json
  def index
    # params[:q] = {website_id_eq:params[:website_id]} if params[:website_id]
    @q = Crawler::Plan.includes(:website).ransack(params[:q])
    @count = @q.result.size
    @per = params[:per].blank? ? 50 : params[:per].to_i
    @pagecount = @count % @per > 0 ? @count / @per + 1 : @count
    @crawler_plans = @q.result.order(:website_id).page(params[:page]).per(@per)
  end


  # 执行采集
  def exce
    ip = request.env['HTTP_X_FORWARDED_FOR'].present? ? request.env['HTTP_X_FORWARDED_FOR'] : request.remote_ip
    puts "ip:#{ip}, count:  #{@@exec_histroy[ip].to_s}"
    @@exec_histroy[ip] = {page:0,count:0} if @@exec_histroy[ip].nil?
    if @@exec_histroy[ip][:page] > 100 or @@exec_histroy[ip][:count] > 10
      @msg = "#{ip}:每天只能尝试采集10次,或100页,您已超过了限制,请明天再来"
      return
    end
    @plans = Crawler::Plan.all
    a = params[:page_a]
    b = params[:page_b]
    if a.blank? or b.blank?
      @msg = "手动采集必须填写页码a-b"
      return
    else
      a = a.to_i
      b = b.to_i
      if b < a
        @msg = "b页不能小于a"
        return
      end

      results = @crawler_plan.exce_works(a, b, params[:include_work_name], params[:filter_work_name], params[:save_flag])
      @works = results[:works]
      time = results[:time]
      data_count = @works.map{|k,v| v.size}.sum
      if results[:ok]
        @msg = "执行完成,共用时 #{time} 秒, 共对#{b-a+1}页进行了采集, #{data_count}条"
        @@exec_histroy[ip][:page] += (b-a+1)
      else
        @msg = "执行中断,止于第#{results[:error_page]}页,共用时 #{time} 秒, 共对#{results[:error_page].to_i-a+1}页进行了采集, 处理数据#{data_count}条
                错误原因:#{results[:error][:title]},<br/>栈:#{results[:error][:contents]}"
        @@exec_histroy[ip][:page] += (results[:error_page].to_i-a+1)
      end
    end
    @@exec_histroy[ip][:count] += 1
  end

  def flush_page
    @crawler_plan.flush_page
    redirect_to action: :index
  end

  def today_finish
    @crawler_plan.today_finish
    redirect_to action: :index
  end

  # GET /crawler/plans/1
  # GET /crawler/plans/1.json
  def show
  end

  # GET /crawler/plans/new
  def new
    @crawler_plan = Crawler::Plan.new
  end

  # GET /crawler/plans/1/edit
  def edit
  end

  # POST /crawler/plans
  # POST /crawler/plans.json
  def create
    @crawler_plan = Crawler::Plan.new(crawler_plan_params)

    respond_to do |format|
      if @crawler_plan.save
        format.html { redirect_to @crawler_plan, notice: 'Plan was successfully created.' }
        format.json { render :show, status: :created, location: @crawler_plan }
      else
        format.html { render :new }
        format.json { render json: @crawler_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /crawler/plans/1
  # PATCH/PUT /crawler/plans/1.json
  def update
    respond_to do |format|
      if @crawler_plan.update(crawler_plan_params)
        format.html { redirect_to @crawler_plan, notice: 'Plan was successfully updated.' }
        format.json { render :show, status: :ok, location: @crawler_plan }
      else
        format.html { render :edit }
        format.json { render json: @crawler_plan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /crawler/plans/1
  # DELETE /crawler/plans/1.json
  def destroy
    @crawler_plan.destroy
    respond_to do |format|
      format.html { redirect_to crawler_plans_url, notice: 'Plan was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_crawler_plan
      @crawler_plan = Crawler::Plan.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def crawler_plan_params
      params.require(:crawler_plan).permit(:website_id, :source, :name, :url, :page, :note)
    end
end
